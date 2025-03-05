import 'package:flutter/material.dart';
import 'place_gift_screen.dart';
import 'find_gift_screen.dart';

/// 主屏幕类
/// 应用的主界面，提供放置礼物和寻找礼物两个主要功能的入口
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('寻宝游戏'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用标题
            const Text(
              '欢迎来到AR寻宝游戏',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 放置礼物按钮 - 导航到放置礼物界面
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaceGiftScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('放置礼物', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            // 寻找礼物按钮 - 导航到寻找礼物界面
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindGiftScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('寻找礼物', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}