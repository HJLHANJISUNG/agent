import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as Math;
import 'database_service.dart';

class ConversationService extends ChangeNotifier {
  // 使用DatabaseService的API URL
  final DatabaseService _databaseService = DatabaseService();
  String get _baseUrl => _databaseService.baseUrl;

  String? _userId;
  String? _token;
  final List<Conversation> _conversations = [];
  int _currentIndex = 0;

  List<Conversation> get conversations => _conversations;
  int get currentIndex => _currentIndex;
  Conversation? get currentConversation =>
      _conversations.isNotEmpty ? _conversations[_currentIndex] : null;
  String? get userId => _userId;

  // 初始化方法，從 SharedPreferences 加載 token 和 userId，並從數據庫加載對話
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('user_id');

    // 如果已登入，則從數據庫加載對話
    if (isLoggedIn) {
      await loadConversationsFromDatabase();
    }

    notifyListeners();
  }

  // 從數據庫加載對話
  Future<void> loadConversationsFromDatabase() async {
    if (_userId == null) return;

    try {
      final conversationsData = await _databaseService.getUserConversations(
        _userId!,
      );

      // 清空當前對話列表
      _conversations.clear();

      // 將數據轉換為Conversation對象
      for (var convData in conversationsData) {
        final messagesMaps = convData['messages'] as List<Map<String, dynamic>>;
        final conversation = Conversation.fromMap(convData, messagesMaps);
        _conversations.add(conversation);
      }

      // 重設當前索引
      _currentIndex = _conversations.isEmpty ? 0 : 0;

      notifyListeners();
      print('成功從數據庫加載 ${_conversations.length} 個對話');
    } catch (e) {
      print('從數據庫加載對話時出錯: $e');
    }
  }

  // 保存當前對話到數據庫
  Future<void> saveCurrentConversation() async {
    if (_userId == null || currentConversation == null) return;

    try {
      // 確保對話有用戶ID
      if (currentConversation!.userId == null) {
        currentConversation!.userId = _userId;
      }

      // 準備數據
      final conversationMap = currentConversation!.toMap();
      final messagesMapList = currentConversation!.messagesToMapList();

      // 保存到數據庫
      await _databaseService.saveConversation(_userId!, {
        ...conversationMap,
        'messages': messagesMapList,
      });

      print('成功保存對話到數據庫: ${currentConversation!.id}');
    } catch (e) {
      print('保存對話到數據庫時出錯: $e');
    }
  }

  // 保存所有對話到數據庫
  Future<void> saveAllConversations() async {
    if (_userId == null || _conversations.isEmpty) return;

    try {
      for (var conversation in _conversations) {
        // 確保對話有用戶ID
        if (conversation.userId == null) {
          conversation.userId = _userId;
        }

        // 準備數據
        final conversationMap = conversation.toMap();
        final messagesMapList = conversation.messagesToMapList();

        // 保存到數據庫
        await _databaseService.saveConversation(_userId!, {
          ...conversationMap,
          'messages': messagesMapList,
        });
      }

      print('成功保存所有對話到數據庫');
    } catch (e) {
      print('保存所有對話到數據庫時出錯: $e');
    }
  }

  // 設置 token 和 userId，並從數據庫加載對話
  Future<void> setAuthInfo(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_id', userId);
    _token = token;
    _userId = userId;

    // 從數據庫加載對話
    await loadConversationsFromDatabase();

    notifyListeners();
  }

  // 清除 token 和 userId，同時清空對話列表
  Future<void> clearAuthInfo() async {
    // 先保存所有對話
    if (isLoggedIn) {
      await saveAllConversations();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    _token = null;
    _userId = null;
    _conversations.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  // 檢查是否已登入
  bool get isLoggedIn => _token != null && _userId != null;

  void addConversation(String title) {
    final conversation = Conversation(title: title, userId: _userId);
    _conversations.add(conversation);
    _currentIndex = _conversations.length - 1;
    notifyListeners();

    // 保存到數據庫
    saveCurrentConversation();
  }

  Future<void> removeConversation(int index) async {
    if (index < 0 || index >= _conversations.length) return;

    // 從數據庫刪除
    if (_userId != null) {
      final conversationId = _conversations[index].id;
      await _databaseService.deleteConversation(conversationId);
    }

    _conversations.removeAt(index);
    if (_currentIndex >= _conversations.length) {
      _currentIndex = _conversations.length - 1;
    }
    notifyListeners();
  }

  void switchConversation(int index) {
    if (index < 0 || index >= _conversations.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  void addMessageToCurrent(String role, String content) {
    if (currentConversation == null) return;
    currentConversation!.messages.add(Message(role: role, content: content));
    currentConversation!.updatedAt = DateTime.now();
    notifyListeners();

    // 保存到數據庫
    saveCurrentConversation();
  }

  Future<void> clearAll() async {
    // 從數據庫刪除所有對話
    if (_userId != null) {
      for (var conversation in _conversations) {
        await _databaseService.deleteConversation(conversation.id);
      }
    }

    _conversations.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  // 自动新建会话并切换为当前会话
  void createNewConversation({String? title}) {
    final conv = Conversation(title: title ?? '新对话', userId: _userId);
    _conversations.add(conv);
    _currentIndex = _conversations.length - 1;
    notifyListeners();

    // 保存到數據庫
    saveCurrentConversation();
  }

  // 修改对话标题
  Future<void> updateConversationTitle(int index, String newTitle) async {
    if (index < 0 || index >= _conversations.length) return;
    _conversations[index].title = newTitle;
    _conversations[index].updatedAt = DateTime.now();
    notifyListeners();

    // 更新數據庫中的標題
    if (_userId != null) {
      final conversationId = _conversations[index].id;
      await _databaseService.updateConversationTitle(conversationId, newTitle);
    }
  }

  // 新增：發送消息到後端並獲取AI回複
  Future<void> sendMessage(String text, {List<PlatformFile>? files}) async {
    print("ConversationService: sendMessage 開始");

    if (!isLoggedIn) {
      print('Error: User not logged in');
      final errorMessage = Message(role: 'assistant', content: '請先登入後再使用聊天功能');
      if (currentConversation == null) {
        createNewConversation();
      }
      currentConversation!.messages.add(errorMessage);
      notifyListeners();
      return;
    }

    if (currentConversation == null) {
      print('Error: No conversation selected.');
      createNewConversation();
      print('Created new conversation: ${currentConversation!.id}');
    }

    print("ConversationService: 當前對話 ID: ${currentConversation!.id}");

    final url = Uri.parse('$_baseUrl/chat');
    print('Sending request to: $url');
    print('Using User ID: $_userId');
    print('Content: $text');

    try {
      // 添加用戶消息到對話
      final userMessage = Message(role: 'user', content: text);
      currentConversation!.messages.add(userMessage);
      notifyListeners(); // 立即更新 UI 顯示用戶消息

      // 添加一條空的助手消息，用於流式更新
      final aiMessage = Message(role: 'assistant', content: '');
      currentConversation!.messages.add(aiMessage);
      notifyListeners();

      http.Response response;
      final Map<String, String> headers = {'Authorization': 'Bearer $_token'};

      // 如果有文件，使用 MultipartRequest
      if (files != null && files.isNotEmpty) {
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll(headers);
        request.fields['content'] = text;

        print('Adding ${files.length} files to request...');
        for (var file in files) {
          if (file.path != null) {
            final fileStream = await http.MultipartFile.fromPath(
              'files',
              file.path!,
              filename: file.name,
            );
            request.files.add(fileStream);
          }
        }

        print('Sending multipart request...');
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }
      // 如果沒有文件，使用普通的 JSON 請求
      else {
        print('Sending JSON request...');
        headers['Content-Type'] = 'application/json';
        response = await http.post(
          url,
          headers: headers,
          body: json.encode({'content': text}),
        );
      }

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print('Parsed response data: $responseData');

        // 更新之前創建的空助手消息
        final lastIndex = currentConversation!.messages.length - 1;
        currentConversation!.messages[lastIndex] = Message(
          role: 'assistant',
          content: responseData['content'],
          solutionId: responseData['solution_id'],
        );
        print('AI message updated');
      } else {
        // 更新空的助手消息為錯誤信息
        final lastIndex = currentConversation!.messages.length - 1;
        currentConversation!.messages[lastIndex] = Message(
          role: 'assistant',
          content: '抱歉，無法獲取回覆。錯誤: ${response.statusCode}\n${response.body}',
        );
        print('Error message updated');
      }
    } catch (e) {
      print('Exception occurred: $e');
      // 檢查是否已經添加了助手消息
      if (currentConversation!.messages.isNotEmpty &&
          currentConversation!.messages.last.role == 'assistant') {
        // 更新已存在的助手消息
        final lastIndex = currentConversation!.messages.length - 1;
        currentConversation!.messages[lastIndex] = Message(
          role: 'assistant',
          content: '抱歉，發生網絡錯誤: $e',
        );
      } else {
        // 添加新的錯誤消息
        currentConversation!.messages.add(
          Message(role: 'assistant', content: '抱歉，發生網絡錯誤: $e'),
        );
      }
    } finally {
      notifyListeners();
    }
  }

  // 新增：模擬流式回應的方法
  Future<void> sendMessageWithStream(
    String text, {
    List<PlatformFile>? files,
  }) async {
    print("ConversationService: sendMessageWithStream 開始");

    if (!isLoggedIn) {
      print('Error: User not logged in');
      final errorMessage = Message(role: 'assistant', content: '請先登入後再使用聊天功能');
      if (currentConversation == null) {
        createNewConversation();
      }
      currentConversation!.messages.add(errorMessage);
      notifyListeners();
      // 保存到數據庫
      saveCurrentConversation();
      return;
    }

    if (currentConversation == null) {
      print('Error: No conversation selected.');
      createNewConversation();
      print('Created new conversation: ${currentConversation!.id}');
    }

    // 添加用戶消息到對話
    final userMessage = Message(role: 'user', content: text);
    currentConversation!.messages.add(userMessage);
    currentConversation!.updatedAt = DateTime.now();

    // --- 新增：同步寫入本地 Question 表 ---
    try {
      final userId = _userId;
      if (userId != null) {
        final questionId = DateTime.now().millisecondsSinceEpoch.toString();
        await _databaseService.database.then(
          (db) => db.insert('Question', {
            'question_id': questionId,
            'user_id': userId,
            'content': text,
            'image_url': null,
            'ask_time': DateTime.now().toIso8601String(),
            'solved': 0,
          }),
        );
      }
    } catch (e) {
      print('本地寫入 Question 失敗: $e');
    }
    // --- 新增結束 ---

    // 添加一條空的助手消息，用於流式更新
    final aiMessage = Message(role: 'assistant', content: '');
    currentConversation!.messages.add(aiMessage);
    notifyListeners();

    // 先保存用戶消息到數據庫
    saveCurrentConversation();

    try {
      final url = Uri.parse('$_baseUrl/chat');
      print('Sending request to: $url');

      // 發送實際請求並獲取完整回答
      http.Response response;
      String fullResponse = '';
      String? solutionId;

      // 先發送請求獲取完整回答
      try {
        final Map<String, String> headers = {'Authorization': 'Bearer $_token'};

        if (files != null && files.isNotEmpty) {
          var request = http.MultipartRequest('POST', url);
          request.headers.addAll(headers);
          request.fields['content'] = text;

          for (var file in files) {
            if (file.path != null) {
              final fileStream = await http.MultipartFile.fromPath(
                'files',
                file.path!,
                filename: file.name,
              );
              request.files.add(fileStream);
            }
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else {
          headers['Content-Type'] = 'application/json';
          response = await http.post(
            url,
            headers: headers,
            body: json.encode({'content': text}),
          );
        }

        if (response.statusCode == 200) {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          fullResponse = responseData['content'];
          solutionId = responseData['solution_id'];
        } else {
          fullResponse =
              '抱歉，無法獲取回覆。錯誤: ${response.statusCode}\n${response.body}';
        }
      } catch (e) {
        print('Request error: $e');
        fullResponse = '抱歉，發生網絡錯誤: $e';
      }

      // 顯示打字機效果
      String currentText = '';
      String displayText = '';

      // 先顯示思考中...
      _updateAssistantMessage('思考中...');
      await Future.delayed(const Duration(milliseconds: 800));

      // 處理延遲標記並移除它們
      String cleanedResponse = fullResponse;
      // 移除所有標記，用於顯示
      cleanedResponse = cleanedResponse
          .replaceAll('<pause-short>', '')
          .replaceAll('<pause-medium>', '')
          .replaceAll('<pause-long>', '');

      // 逐字顯示回答
      List<String> characters = cleanedResponse.split('');

      for (int i = 0; i < characters.length; i++) {
        // 每添加一個字符就更新一次消息
        currentText += characters[i];
        displayText = currentText;

        // 更新助手消息
        if (currentConversation != null &&
            currentConversation!.messages.isNotEmpty) {
          final lastIndex = currentConversation!.messages.length - 1;
          if (currentConversation!.messages[lastIndex].role == 'assistant') {
            currentConversation!.messages[lastIndex] = Message(
              role: 'assistant',
              content: displayText,
              solutionId: solutionId,
            );
            currentConversation!.updatedAt = DateTime.now();
            notifyListeners();

            // 每十個字符保存一次對話（減少數據庫操作次數）
            if (i % 10 == 0 && i > 0) {
              saveCurrentConversation();
            }
          }
        }

        // 根據字符類型調整延遲時間，使顯示更自然
        int delay = 20; // 基本延遲時間，加快一點

        // 檢查是否需要根據上下文暫停
        if (i + 10 < cleanedResponse.length) {
          String nextChars = cleanedResponse.substring(i, i + 10);
          if (nextChars.contains('<pause-short>')) {
            delay = 150;
          } else if (nextChars.contains('<pause-medium>')) {
            delay = 300;
          } else if (nextChars.contains('<pause-long>')) {
            delay = 500;
          }
        }

        // 標點符號後面稍微停頓長一些
        if ('.。!！?？,，;；:：'.contains(characters[i])) {
          delay = Math.max(delay, 150);
        }
        // 換行符後停頓更長
        else if (characters[i] == '\n') {
          delay = Math.max(delay, 250);
        }

        // 每幾個字符檢查一下是否有特殊標記需要跳過
        if (i % 5 == 0 && i + 15 < cleanedResponse.length) {
          String chunk = cleanedResponse.substring(i, i + 15);
          if (chunk.contains('<pause-')) {
            int pauseIndex = chunk.indexOf('<pause-');
            if (pauseIndex >= 0) {
              int endIndex = chunk.indexOf('>', pauseIndex);
              if (endIndex >= 0) {
                String pauseType = chunk.substring(pauseIndex + 7, endIndex);
                if (pauseType == 'short') {
                  delay = 150;
                } else if (pauseType == 'medium') {
                  delay = 300;
                } else if (pauseType == 'long') {
                  delay = 500;
                }
              }
            }
          }
        }

        await Future.delayed(Duration(milliseconds: delay));
      }

      // 完成後，確保顯示的是乾淨的文本（沒有暫停標記）
      if (fullResponse.contains('<pause-')) {
        String finalText = fullResponse
            .replaceAll('<pause-short>', '')
            .replaceAll('<pause-medium>', '')
            .replaceAll('<pause-long>', '');

        // 更新最終消息並保存
        if (currentConversation != null &&
            currentConversation!.messages.isNotEmpty) {
          final lastIndex = currentConversation!.messages.length - 1;
          if (currentConversation!.messages[lastIndex].role == 'assistant') {
            currentConversation!.messages[lastIndex] = Message(
              role: 'assistant',
              content: finalText,
              solutionId: solutionId,
            );
            currentConversation!.updatedAt = DateTime.now();
            notifyListeners();

            // 保存最終結果到數據庫
            saveCurrentConversation();
          }
        }
      } else {
        // 保存最終結果到數據庫
        saveCurrentConversation();
      }
    } catch (e) {
      print('Exception occurred: $e');
      _updateAssistantMessage('抱歉，發生網絡錯誤: $e');
      // 保存錯誤信息到數據庫
      saveCurrentConversation();
    }
  }

  // 更新助手消息的輔助方法
  void _updateAssistantMessage(String content, {String? solutionId}) {
    if (currentConversation != null &&
        currentConversation!.messages.isNotEmpty) {
      final lastIndex = currentConversation!.messages.length - 1;
      if (currentConversation!.messages[lastIndex].role == 'assistant') {
        currentConversation!.messages[lastIndex] = Message(
          role: 'assistant',
          content: content,
          solutionId: solutionId,
        );
        currentConversation!.updatedAt = DateTime.now();
        notifyListeners();

        // 保存到數據庫
        saveCurrentConversation();
      }
    }
  }

  // 新增：发送意见反馈
  Future<bool> sendFeedback({
    required String solutionId,
    required int rating,
    required String comment,
  }) async {
    if (!isLoggedIn) {
      print('Error: User not logged in');
      return false;
    }

    final url = Uri.parse('$_baseUrl/feedbacks/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'solution_id': solutionId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        print('Feedback sent successfully');
        return true;
      } else {
        print('Failed to send feedback. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('An error occurred while sending feedback: $e');
      return false;
    }
  }
}
