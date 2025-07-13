import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationService extends ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000/api'; // 修正為正確的後端 API 基礎 URL
  String? _userId;
  String? _token;
  final List<Conversation> _conversations = [];
  int _currentIndex = 0;

  List<Conversation> get conversations => _conversations;
  int get currentIndex => _currentIndex;
  Conversation? get currentConversation =>
      _conversations.isNotEmpty ? _conversations[_currentIndex] : null;

  // 初始化方法，從 SharedPreferences 加載 token 和 userId
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  // 設置 token 和 userId
  Future<void> setAuthInfo(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_id', userId);
    _token = token;
    _userId = userId;
    notifyListeners();
  }

  // 清除 token 和 userId（登出時使用）
  Future<void> clearAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    _token = null;
    _userId = null;
    notifyListeners();
  }

  // 檢查是否已登入
  bool get isLoggedIn => _token != null && _userId != null;

  void addConversation(String title) {
    _conversations.add(Conversation(title: title));
    _currentIndex = _conversations.length - 1;
    notifyListeners();
  }

  void removeConversation(int index) {
    if (index < 0 || index >= _conversations.length) return;
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
    notifyListeners();
  }

  void clearAll() {
    _conversations.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  // 自动新建会话并切换为当前会话
  void createNewConversation({String? title}) {
    final conv = Conversation(title: title ?? '新对话');
    _conversations.add(conv);
    _currentIndex = _conversations.length - 1;
    notifyListeners();
  }

  // 新增：修改对话标题
  void updateConversationTitle(int index, String newTitle) {
    if (index < 0 || index >= _conversations.length) return;
    _conversations[index].title = newTitle;
    _conversations[index].updatedAt = DateTime.now();
    notifyListeners();
  }

  // 新增：发送消息到后端并获取AI回复
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

        final aiMessage = Message(
          role: 'assistant',
          content: responseData['content'],
          solutionId: responseData['solution_id'],
        );
        currentConversation!.messages.add(aiMessage);
        print('AI message added to conversation');
      } else {
        final errorMessage = Message(
          role: 'assistant',
          content: '抱歉，無法獲取回覆。錯誤: ${response.statusCode}\n${response.body}',
        );
        currentConversation!.messages.add(errorMessage);
        print('Error message added to conversation');
      }
    } catch (e) {
      print('Exception occurred: $e');
      final errorMessage = Message(role: 'assistant', content: '抱歉，發生網絡錯誤: $e');
      currentConversation!.messages.add(errorMessage);
    } finally {
      notifyListeners();
      print('UI updated via notifyListeners()');
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
