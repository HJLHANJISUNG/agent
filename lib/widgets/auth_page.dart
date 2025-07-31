import 'package:flutter/material.dart';
// import 'aurora_background.dart'; // 不再需要
import 'package:animated_text_kit/animated_text_kit.dart';
import '../services/database_service.dart'; // 導入 DatabaseService
import '../services/conversation_service.dart'; // 導入 ConversationService
import 'package:provider/provider.dart'; // 導入 Provider

class AuthPage extends StatefulWidget {
  final Function(bool isLoggedIn, String? username, String? email)
  onAuthChanged;

  const AuthPage({super.key, required this.onAuthChanged});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true; // true: 登录, false: 注册
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController(); // 新增 email controller
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _databaseService = DatabaseService(); // 創建 DatabaseService 實例

  // 模拟管理员账号
  static const Map<String, String> _adminAccounts = {
    'admin': 'admin123',
    'administrator': 'admin456',
    'manager': 'manager789',
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose(); // 記得 dispose
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B2B), Color(0xFFFF6A3D)], // 使用側邊欄的紅橙漸層
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Title
                SizedBox(
                  width: 450.0,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 改回白色
                      fontFamily: 'Agne',
                      shadows: [
                        Shadow(
                          blurRadius: 7.0,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'IP智慧解答专家',
                          speed: const Duration(milliseconds: 150),
                        ),
                        TypewriterAnimatedText(
                          '您的智能伙伴',
                          speed: const Duration(milliseconds: 150),
                        ),
                        TypewriterAnimatedText(
                          '随时为您服务',
                          speed: const Duration(milliseconds: 150),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                // Login/Register Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white, // 改為不透明的白色
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), // 減輕陰影
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.insights,
                              color: Color(0xFF6C63FF),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              '欢迎回来',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Login/Register form
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.1),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: _isLogin
                              ? _LoginForm(
                                  key: const ValueKey('login'),
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isLoading: _isLoading,
                                  onLogin: _handleLogin,
                                  onSwitch: () =>
                                      setState(() => _isLogin = false),
                                )
                              : _RegisterForm(
                                  key: const ValueKey('register'),
                                  usernameController: _usernameController,
                                  emailController:
                                      _emailController, // 傳遞 controller
                                  passwordController: _passwordController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  isLoading: _isLoading,
                                  onRegister: _handleRegister,
                                  onSwitch: () =>
                                      setState(() => _isLogin = true),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1000)); // 模拟网络请求

      if (_isLogin) {
        // 登录逻辑
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        if (_adminAccounts.containsKey(username) &&
            _adminAccounts[username] == password) {
          // 管理员登录成功
          widget.onAuthChanged(true, username, null); // 登录时 email 为 null
          _showSuccessDialog('登录成功', '欢迎回来，管理员！');
        } else {
          // 普通用户登录
          widget.onAuthChanged(true, username, null); // 登录时 email 为 null
          _showSuccessDialog('登录成功', '欢迎使用IP智慧解答专家！');
        }
      } else {
        // 注册逻辑
        final username = _usernameController.text.trim();
        final email = _emailController.text.trim();
        widget.onAuthChanged(true, username, email); // 注册时传递 email
        _showSuccessDialog('注册成功', '账户创建成功，欢迎使用！');
      }
    } catch (e) {
      _showErrorDialog('操作失败', '请检查网络连接后重试');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 新增：处理登录逻辑
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 取得 ConversationService 實例
    final conversationService = Provider.of<ConversationService>(
      context,
      listen: false,
    );

    // 管理員帳號特殊处理
    if (_adminAccounts.containsKey(email) &&
        _adminAccounts[email] == password) {
      widget.onAuthChanged(true, email, null);
      setState(() => _isLoading = false);
      return;
    }

    // 使用 DatabaseService 登入
    try {
      final result = await _databaseService.loginUser(email, password);

      if (result['success']) {
        final tokenData = result['token'];
        final accessToken = tokenData['access_token'];
        final userId = tokenData['user_id'];
        final userName = tokenData['username'];
        await conversationService.setAuthInfo(accessToken, userId);
        widget.onAuthChanged(true, userName, email);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登入成功！')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登入失败：${result['error']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发生错误：$e')));
    }

    setState(() => _isLoading = false);
  }

  // 新增：处理注册逻辑
  void _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写所有必填字段')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('开始注册流程');
      print('用户名: ${_usernameController.text.trim()}');
      print('邮箱: ${_emailController.text.trim()}');

      // 使用 DatabaseService 註冊
      final result = await _databaseService.registerUser(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('注册结果: $result');

      if (result['success']) {
        print('注册成功，准备切换状态');

        // 註冊成功後自動登入，始终用用户名
        final loginResult = await _databaseService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (loginResult['success']) {
          // 取得 ConversationService 實例
          final conversationService = Provider.of<ConversationService>(
            context,
            listen: false,
          );

          // 從登入結果中獲取 token 和 user_id
          final tokenData = loginResult['token'];
          final accessToken = tokenData['access_token'];
          final userId = tokenData['user_id'];

          // 保存 token 和 user_id 到 ConversationService
          await conversationService.setAuthInfo(accessToken, userId);

          // 通知應用程序用戶已登入
          widget.onAuthChanged(
            true,
            _usernameController.text.trim(),
            _emailController.text.trim(),
          );
        } else {
          // 註冊成功但登入失敗，仍然視為註冊成功
          widget.onAuthChanged(
            true,
            _usernameController.text.trim(),
            _emailController.text.trim(),
          );
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('注册成功！')));
      } else {
        print('注册失败: ${result['error']}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('注册失敗：${result['error']}')));
        // 注册失败时重置加载状态
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('注册过程发生错误: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发生错误：$e')));
      // 发生错误时重置加载状态
      setState(() => _isLoading = false);
    }
  }
}

// 新增登录表单组件
class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onSwitch;
  const _LoginForm({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
    required this.onSwitch,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: '电子邮箱',
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFFE60012),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '密码',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFFE60012),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60012),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '登录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading ? null : onSwitch,
          child: const Text(
            '没有账号？注册',
            style: TextStyle(color: Color(0xFFE60012)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// 新增注册表单组件
class _RegisterForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController; // 新增
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onSwitch;
  const _RegisterForm({
    Key? key,
    required this.usernameController,
    required this.emailController, // 新增
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onRegister,
    required this.onSwitch,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: '用户名',
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFFE60012),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: '电子邮箱',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return '请输入有效的电子邮箱';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '密码',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFFE60012),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '确认密码',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFFE60012),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60012),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '注册',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading ? null : onSwitch,
          child: const Text(
            '已有账号？登录',
            style: TextStyle(color: Color(0xFFE60012)),
          ),
        ),
      ],
    );
  }
}
