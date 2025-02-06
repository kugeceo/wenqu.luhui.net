import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SingleInstance {
  static Future<bool> check() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final lockFile = File('${tempDir.path}/svga_viewer.lock');
      
      // 检查锁文件
      if (await lockFile.exists()) {
        try {
          // 尝试删除锁文件，如果能删除说明之前的实例已经关闭
          await lockFile.delete();
        } catch (e) {
          // 如果无法删除，说明另一个实例正在运行
          print('应用已在运行中');
          return false;
        }
      }
      
      // 创建锁文件
      await lockFile.writeAsString(DateTime.now().toString());
      
      // 注册程序退出时的清理
      ProcessSignal.sigint.watch().listen((_) async {
        await lockFile.delete();
        exit(0);
      });
      
      return true;
    } catch (e) {
      print('检查单例时出错: $e');
      return true; // 出错时允许运行
    }
  }
} 