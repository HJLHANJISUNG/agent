import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class DbTestPage extends StatefulWidget {
  const DbTestPage({super.key});

  @override
  _DbTestPageState createState() => _DbTestPageState();
}

class _DbTestPageState extends State<DbTestPage> {
  final DatabaseService _dbService = DatabaseService();
  List<User> _users = [];
  String _message = '';

  @override
  void initState() {
    super.initState();
    _refreshUserList();
  }

  Future<void> _refreshUserList() async {
    final data = await _dbService.getUsers();
    setState(() {
      _users = data.map((item) => User.fromMap(item)).toList();
      _message = '用户列表已刷新';
    });
  }

  Future<void> _addUser() async {
    final newUser = User(
      userId: const Uuid().v4(),
      username: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
      registerDate: DateTime.now(),
    );
    await _dbService.insertUser(newUser.toMap());
    setState(() {
      _message = '用户 ${newUser.username} 已添加';
    });
    _refreshUserList();
  }

  Future<void> _updateUser() async {
    if (_users.isEmpty) {
      setState(() => _message = '没有用户可更新');
      return;
    }
    final userToUpdate = _users.first;
    final updatedUser = User(
      userId: userToUpdate.userId,
      username: 'updated_${userToUpdate.username}',
      email: userToUpdate.email,
      registerDate: userToUpdate.registerDate,
    );
    await _dbService.updateUser(updatedUser.toMap());
    setState(() => _message = '用户 ${userToUpdate.username} 已更新');
    _refreshUserList();
  }

  Future<void> _deleteUser() async {
    if (_users.isEmpty) {
      setState(() => _message = '没有用户可删除');
      return;
    }
    final userToDelete = _users.first;
    await _dbService.deleteUser(userToDelete.userId);
    setState(() => _message = '用户 ${userToDelete.username} 已删除');
    _refreshUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据库操作测试')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _addUser, child: const Text('新增用户')),
                ElevatedButton(
                  onPressed: _updateUser,
                  child: const Text('更新用户'),
                ),
                ElevatedButton(
                  onPressed: _deleteUser,
                  child: const Text('删除用户'),
                ),
                ElevatedButton(
                  onPressed: _refreshUserList,
                  child: const Text('刷新列表'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '当前用户列表:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: Text(user.userId.substring(0, 8)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
