import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/main_layout.dart';
import 'services/conversation_service.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 初始化 FFI（僅限桌面平台）for sqflite
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 創建 ConversationService 實例並初始化
  final conversationService = ConversationService();
  await conversationService.initialize();

  await DatabaseService().insertTestKnowledge(); // 啟動時自動插入測試知識庫數據

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConversationService>(
          create: (_) => conversationService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP智慧解答專家',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE60012)),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}
