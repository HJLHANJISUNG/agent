import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final String _baseUrl = 'http://127.0.0.1:8000/api'; // 後端 API 基礎 URL

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

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
  }

  // 新增：註冊用戶
  Future<Map<String, dynamic>> registerUser(
    String username,
    String email,
    String password,
  ) async {
    try {
      // 修正 API 路徑，添加末尾斜線
      final url = Uri.parse('$_baseUrl/users/');
      print('Registering user at: $url');
      print('Username: $username, Email: $email');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out. Please try again.');
            },
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

  // 新增：登入用戶
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // 修正 API 路徑
      final url = Uri.parse('$_baseUrl/users/token');
      print('Logging in user at: $url');
      print('Email: $email');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
              'username': 'temp', // 後端需要這個欄位，但登入時不使用
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out. Please try again.');
            },
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

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('User');
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
}
