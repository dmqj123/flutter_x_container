import 'package:flutter/material.dart';
import 'package:flutter_x_container/system.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 禁用 WebView 调试功能，防止调试器中断
  PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

  // 针对 Android 平台禁用 WebView 调试
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(false);
  }

  runApp(const MyApp());
}

// 定义应用的浅色主题样式
ThemeData lightMode = ThemeData(
  // 设置主题亮度为浅色
  brightness: Brightness.light,
  // 配置浅色主题的颜色方案
  colorScheme:
      ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 116, 183)),
);

// 定义应用的深色主题样式
ThemeData darkMode = ThemeData(
  // 设置主题亮度为深色
  brightness: Brightness.dark,
  // 配置深色主题的颜色方案
  colorScheme: ColorScheme.dark(
    // surface颜色用于卡片、画布等表面元素（深色主题）
    surface: Colors.grey.shade900,
    // primary颜色用于主要的UI元素，如顶部导航栏（深色主题）
    primary: Colors.grey.shade800,
    // secondary颜色用于次级UI元素，如浮动按钮等（深色主题）
    secondary: Colors.grey.shade700,
  ),
  useMaterial3: true,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 去除右上角的DEBUG图标
      theme: lightMode,
      darkTheme: darkMode,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  void GetPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    GetPrefs();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedText(
                  text: "FlutterX Container",
                  animation: _animation,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Animation<double> animation;

  const AnimatedText({
    super.key,
    required this.text,
    required this.animation,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(text.length, (index) {
            // 计算每个字母的动画延迟
            final letterProgress =
                (animation.value * text.length - index).clamp(0.0, 1.0);
            final letterAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: AlwaysStoppedAnimation(letterProgress),
                curve: Curves.elasticOut,
              ),
            );

            return Opacity(
              opacity: letterProgress,
              child: Transform.scale(
                scale: letterAnimation.value,
                child: Text(
                  text[index],
                  style: style,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
