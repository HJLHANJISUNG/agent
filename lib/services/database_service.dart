import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  // 根據平台選擇適當的API URL
  String get baseUrl {
    if (kIsWeb) {
      // Web平台使用相對路徑
      return '/api';
    } else if (Platform.isAndroid) {
      // Android模擬器中，localhost對應於10.0.2.2
      return 'http://10.0.2.2:8000/api';
    } else if (Platform.isIOS) {
      // iOS模擬器中使用localhost
      return 'http://localhost:8000/api';
    } else {
      // 桌面平台使用localhost
      return 'http://localhost:8000/api';
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app_database.db');
    return await openDatabase(
      path,
      version: 3, // 升級到版本3，Question表新增solved欄位
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 當創建數據庫時調用
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE User(
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        register_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Question(
        question_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        ask_time TEXT NOT NULL,
        solved INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES User(user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE Protocol(
        protocol_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        rfc_number TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Knowledge(
        knowledge_id TEXT PRIMARY KEY,
        protocol_id TEXT NOT NULL,
        content TEXT NOT NULL,
        source TEXT,
        update_time TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES Protocol(protocol_id)
      )
    ''');

    // 新增對話表
    await db.execute('''
      CREATE TABLE Conversation(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 新增消息表
    await db.execute('''
      CREATE TABLE Message(
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        solution_id TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES Conversation(id)
      )
    ''');

    // 新增 Feedback 表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Feedback(
        feedback_id TEXT PRIMARY KEY,
        user_id TEXT,
        solution_id TEXT,
        rating INTEGER,
        comment TEXT,
        created_at TEXT,
        status TEXT
      )
    ''');
  }

  // 當升級數據庫時調用
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2 && newVersion >= 2) {
      // 從舊版升級時補建 Feedback 表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Feedback(
          feedback_id TEXT PRIMARY KEY,
          user_id TEXT,
          solution_id TEXT,
          rating INTEGER,
          comment TEXT,
          created_at TEXT,
          status TEXT
        )
      ''');
    }

    // 從版本2升級到版本3：Question表新增solved欄位
    if (oldVersion < 3 && newVersion >= 3) {
      try {
        await db.execute(
          'ALTER TABLE Question ADD COLUMN solved INTEGER DEFAULT 0',
        );
      } catch (e) {
        print('Add solved column failed (maybe already exists): $e');
      }
    }
  }

  // 封裝HTTP請求，添加自動重試和更好的錯誤處理
  Future<http.Response> _safeHttpRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final url = Uri.parse(
      '${baseUrl}${path.startsWith('/') ? path : '/$path'}',
    );
    headers ??= {};

    if (body != null && !headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }

    int attempts = 0;
    late http.Response response;

    while (attempts < maxRetries) {
      attempts++;
      try {
        print('Attempt $attempts: Sending $method request to $url');

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(url, headers: headers).timeout(timeout);
            break;
          case 'POST':
            response = await http
                .post(url, headers: headers, body: body)
                .timeout(timeout);
            break;
          case 'PUT':
            response = await http
                .put(url, headers: headers, body: body)
                .timeout(timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(url, headers: headers)
                .timeout(timeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        // 成功，直接返回
        return response;
      } on TimeoutException catch (e) {
        print('Request timed out (attempt $attempts): $e');
        if (attempts >= maxRetries) rethrow;
      } on SocketException catch (e) {
        print('Socket exception (attempt $attempts): $e');
        if (attempts >= maxRetries) rethrow;
      } catch (e) {
        print('Other error (attempt $attempts): $e');
        if (attempts >= maxRetries) rethrow;
      }

      // 延遲後重試
      if (attempts < maxRetries) {
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }

    // 不應該到達這裡，但為了類型安全
    throw Exception('All retry attempts failed');
  }

  // 修改註冊用戶方法，使用新的安全HTTP請求
  Future<Map<String, dynamic>> registerUser(
    String username,
    String email,
    String password,
  ) async {
    try {
      print('Registering user: $username, Email: $email');

      try {
        // 先嘗試ping服務器，確認連接狀態
        print('嘗試連接服務器...');
        final pingResponse = await _safeHttpRequest(
          'GET',
          '',
          timeout: const Duration(seconds: 5),
        );
        print('服務器響應: ${pingResponse.statusCode}');
      } catch (e) {
        print('無法連接到服務器: $e');
        // 這裡不返回錯誤，而是繼續嘗試註冊
      }

      // 發送註冊請求
      final response = await _safeHttpRequest(
        'POST',
        '/users/',
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = json.decode(utf8.decode(response.bodyBytes));
        return {'success': true, 'user': userData};
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          errorMessage =
              errorData['detail'] ??
              'Registration failed: ${response.statusCode}';
        } catch (e) {
          errorMessage =
              'Registration failed: ${response.statusCode}. Unable to parse error message.';
        }
        return {'success': false, 'error': errorMessage};
      }
    } on SocketException catch (e) {
      print('Socket Exception during registration: $e');
      return {
        'success': false,
        'error':
            'Network error: Unable to connect to server. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('Timeout Exception during registration: $e');
      return {
        'success': false,
        'error': 'Connection timed out. Server might be down or unreachable.',
      };
    } on FormatException catch (e) {
      print('Format Exception during registration: $e');
      return {
        'success': false,
        'error': 'Invalid data format received from server.',
      };
    } catch (e) {
      print('Exception during registration: $e');
      return {'success': false, 'error': 'Exception: $e'};
    }
  }

  // 更新登入方法，使用新的安全HTTP請求
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('Logging in user: $email');

      final response = await _safeHttpRequest(
        'POST',
        '/users/token',
        body: json.encode({
          'email': email,
          'password': password,
          'username': 'temp', // 後端需要這個欄位，但登入時不使用
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final tokenData = json.decode(utf8.decode(response.bodyBytes));
        return {'success': true, 'token': tokenData};
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          errorMessage =
              errorData['detail'] ?? 'Login failed: ${response.statusCode}';
        } catch (e) {
          errorMessage =
              'Login failed: ${response.statusCode}. Unable to parse error message.';
        }
        return {'success': false, 'error': errorMessage};
      }
    } on SocketException catch (e) {
      print('Socket Exception during login: $e');
      return {
        'success': false,
        'error':
            'Network error: Unable to connect to server. Please check your internet connection.',
      };
    } on TimeoutException catch (e) {
      print('Timeout Exception during login: $e');
      return {
        'success': false,
        'error': 'Connection timed out. Server might be down or unreachable.',
      };
    } on FormatException catch (e) {
      print('Format Exception during login: $e');
      return {
        'success': false,
        'error': 'Invalid data format received from server.',
      };
    } catch (e) {
      print('Exception during login: $e');
      return {'success': false, 'error': 'Exception: $e'};
    }
  }

  // User CRUD Operations
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('User', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'User',
      user,
      where: 'user_id = ?',
      whereArgs: [user['user_id']],
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete('User', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'User',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // 對話相關操作

  // 保存對話到數據庫
  Future<void> saveConversation(
    String userId,
    Map<String, dynamic> conversation,
  ) async {
    final db = await database;

    // 開始事務
    await db.transaction((txn) async {
      // 從 conversation 中提取 messages 並移除，以便插入到 Conversation 表
      final messagesJson = conversation.remove('messages');

      // 保存對話基本信息
      await txn.insert(
        'Conversation',
        conversation,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 獲取該對話的消息
      final List<dynamic> messages = messagesJson is String
          ? jsonDecode(messagesJson)
          : [];

      // 先刪除該對話的舊消息
      await txn.delete(
        'Message',
        where: 'conversation_id = ?',
        whereArgs: [conversation['id']],
      );

      // 保存新消息
      for (var message in messages) {
        await txn.insert(
          'Message',
          message,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // 獲取用戶的所有對話
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final db = await database;

    // 獲取用戶的所有對話
    final conversations = await db.query(
      'Conversation',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    // 為每個對話獲取消息
    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      final messages = await db.query(
        'Message',
        where: 'conversation_id = ?',
        whereArgs: [conversation['id']],
        orderBy: 'timestamp ASC',
      );

      conversations[i] = {...conversation, 'messages': jsonEncode(messages)};
    }

    return conversations;
  }

  // 刪除對話及其消息
  Future<void> deleteConversation(String conversationId) async {
    final db = await database;

    await db.transaction((txn) async {
      // 先刪除對話的所有消息
      await txn.delete(
        'Message',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );

      // 再刪除對話本身
      await txn.delete(
        'Conversation',
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });
  }

  // 更新對話標題
  Future<void> updateConversationTitle(
    String conversationId,
    String newTitle,
  ) async {
    final db = await database;

    await db.update(
      'Conversation',
      {'title': newTitle, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // 用戶統計數據查詢
  Future<int> getUserQuestionCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Question WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUserSolvedCount(String userId) async {
    final db = await database;
    // 假設已解決的問題有一個 solved 欄位為 1
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Question WHERE user_id = ? AND solved = 1',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUserKnowledgeCount(String userId) async {
    final db = await database;
    // 假設 Knowledge 有 user_id 欄位
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Knowledge WHERE protocol_id IN (SELECT protocol_id FROM Protocol)',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUserFeedbackCount(String userId) async {
    final db = await database;
    // 假設 Feedback 有 user_id 欄位
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Feedback WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 標記問題為已解決
  Future<void> markQuestionSolved(String questionId) async {
    final db = await database;
    await db.update(
      'Question',
      {'solved': 1},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // 新增知識條目
  Future<void> addKnowledge(Map<String, dynamic> knowledge) async {
    final db = await database;
    await db.insert('Knowledge', knowledge);
  }

  // 新增反饋
  Future<void> addFeedback(Map<String, dynamic> feedback) async {
    final db = await database;
    await db.insert('Feedback', feedback);
  }

  // 用戶總數
  Future<int> getUserCount() async {
    final db = await database;
    // 若 User 表不存在則自動新建
    await db.execute('''CREATE TABLE IF NOT EXISTS User(
      user_id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      register_date TEXT NOT NULL
    )''');
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM User');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 管理員統計：活躍用戶數（最近7天有註冊）
  Future<int> getActiveUserCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM User WHERE register_date > ?',
      [DateTime.now().subtract(Duration(days: 7)).toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 管理員統計：新用戶增長（最近7天註冊）
  Future<int> getNewUserCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM User WHERE register_date > ?',
      [DateTime.now().subtract(Duration(days: 7)).toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 管理員統計：解決率
  Future<double> getSolvedRate() async {
    final db = await database;
    final total = await db.rawQuery('SELECT COUNT(*) as cnt FROM Question');
    final solved = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Question WHERE solved = 1',
    );
    final totalCount = Sqflite.firstIntValue(total) ?? 0;
    final solvedCount = Sqflite.firstIntValue(solved) ?? 0;
    if (totalCount == 0) return 0.0;
    return solvedCount / totalCount;
  }

  // 管理員統計：平均回答時間（秒）
  Future<double> getAverageAnswerTime() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(strftime(\'%s\', timestamp) - strftime(\'%s\', ask_time)) as avg_time FROM Message JOIN Question ON Message.question_id = Question.question_id WHERE Message.role = "assistant" AND Question.ask_time IS NOT NULL',
    );
    return result.first['avg_time'] != null
        ? (result.first['avg_time'] as num).toDouble()
        : 0.0;
  }

  // 管理員統計：知識庫最近更新
  Future<String> getLastKnowledgeUpdate() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(update_time) as last_update FROM Knowledge',
    );
    return result.first['last_update']?.toString() ?? '';
  }

  // 用戶列表
  Future<List<Map<String, dynamic>>> getUsers({int limit = 100}) async {
    final db = await database;
    await db.execute('''CREATE TABLE IF NOT EXISTS User(
      user_id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      register_date TEXT NOT NULL
    )''');
    return await db.query('User', limit: limit, orderBy: 'register_date DESC');
  }

  // 主題分布
  Future<Map<String, int>> getProtocolDistribution() async {
    final db = await database;
    await db.execute('''CREATE TABLE IF NOT EXISTS Question(
      question_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      content TEXT NOT NULL,
      image_url TEXT,
      ask_time TEXT NOT NULL,
      solved INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES User(user_id)
    )''');
    final result = await db.rawQuery(
      'SELECT protocol_id, COUNT(*) as cnt FROM Question GROUP BY protocol_id',
    );
    return {
      for (var row in result)
        (row['protocol_id'] ?? '未知') as String: row['cnt'] as int,
    };
  }

  // 反饋列表
  Future<List<Map<String, dynamic>>> getFeedbacks({int limit = 100}) async {
    final db = await database;
    await db.execute('''CREATE TABLE IF NOT EXISTS Feedback(
      feedback_id TEXT PRIMARY KEY,
      user_id TEXT,
      solution_id TEXT,
      rating INTEGER,
      comment TEXT,
      created_at TEXT,
      status TEXT
    )''');
    return await db.query('Feedback', limit: limit, orderBy: 'created_at DESC');
  }

  // 反饋統計
  Future<Map<String, dynamic>> getFeedbackStats() async {
    final db = await database;
    await db.execute('''CREATE TABLE IF NOT EXISTS Feedback(
      feedback_id TEXT PRIMARY KEY,
      user_id TEXT,
      solution_id TEXT,
      rating INTEGER,
      comment TEXT,
      created_at TEXT,
      status TEXT
    )''');
    final total = await db.rawQuery('SELECT COUNT(*) as cnt FROM Feedback');
    final avg = await db.rawQuery('SELECT AVG(rating) as avg FROM Feedback');
    final pending = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM Feedback WHERE status = "pending"',
    );
    return {
      'total_count': Sqflite.firstIntValue(total) ?? 0,
      'average_rating': avg.first['avg'] ?? 0.0,
      'pending_count': Sqflite.firstIntValue(pending) ?? 0,
    };
  }
}
