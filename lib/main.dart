import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart' as ui;
import 'package:window_manager/window_manager.dart';
import 'single_instance.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui show Image, decodeImageFromList;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 检查是否已有实例运行
  bool canRun = await SingleInstance.check();
  if (!canRun) {
    exit(0);
  }

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 设置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'SVGA预览器',
  );

  // 配置窗口
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 创建视图模型
  final viewModel = SVGAViewModel();

  // 设置方法通道处理文件打开
  const channel = MethodChannel('svga_viewer');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'openFile') {
      final String filePath = call.arguments as String;
      if (filePath.toLowerCase().endsWith('.svga')) {
        await viewModel.processSVGAFile(filePath);
      }
    }
  });

  // 如果有命令行参数（双击文件打开），处理第一个文件
  if (args.isNotEmpty && args.first.toLowerCase().endsWith('.svga')) {
    await viewModel.processSVGAFile(args.first);
  }

  // 设置窗口事件处理
  await windowManager.setPreventClose(false);

  runApp(
    ChangeNotifierProvider(
      create: (context) => viewModel,
      child: const MyApp(),
    ),
  );
}

// SVGA视图模型，用于管理状态
class SVGAViewModel extends ChangeNotifier {
  List<File> _frames = [];
  int _currentFrameIndex = 0;
  bool _isDragging = false;
  File? _svgaFile;
  String? _currentFileName;
  double _fps = 0;  // 添加帧率属性
  double _duration = 0;  // 添加持续时间属性（秒）
  double _memoryUsage = 0;  // 添加内存占用属性（MB）

  List<File> get frames => _frames;
  int get currentFrameIndex => _currentFrameIndex;
  bool get isDragging => _isDragging;
  File? get currentFrame => _frames.isNotEmpty ? _frames[_currentFrameIndex] : null;
  File? get svgaFile => _svgaFile;
  String? get currentFileName => _currentFileName;
  double get fps => _fps;  // 帧率getter
  double get duration => _duration;  // 持续时间getter
  double get memoryUsage => _memoryUsage;  // 内存占用getter

  // 清理所有状态
  Future<void> _clearState() async {
    print('开始清理状态...');
    // 清理内存中的状态
    _frames.clear();
    _currentFrameIndex = 0;
    _svgaFile = null;
    _currentFileName = null;
    _fps = 0;
    _duration = 0;
    _memoryUsage = 0;  // 清空内存占用
    print('内存状态已清理');
    
    // 清理临时目录中的帧图片
    try {
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory('${tempDir.path}/svga_frames');
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
        print('临时目录已删除');
      }
    } catch (e) {
      print('清理临时目录失败: $e');
    }
    
    notifyListeners();
    print('状态清理完成');
  }

  // 设置拖拽状态
  void setDragging(bool value) {
    _isDragging = value;
    notifyListeners();
  }

  // 设置当前帧索引
  void setCurrentFrameIndex(int index) {
    if (index >= 0 && index < _frames.length) {
      _currentFrameIndex = index;
      notifyListeners();
    }
  }

  // 处理SVGA文件
  Future<void> processSVGAFile(String filePath) async {
    print('开始处理新的SVGA文件: ${path.basename(filePath)}');
    
    try {
      // 先清空所有状态和缓存
      await _clearState();
      
      // 清除图片缓存
      imageCache.clear();
      imageCache.clearLiveImages();
      print('图片缓存已清空');

      // 设置文件名
      _currentFileName = path.basename(filePath);
      notifyListeners(); // 立即通知文件名更新
      
      // 创建临时目录存储帧图片
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory('${tempDir.path}/svga_frames');
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
      await framesDir.create(recursive: true);
      print('创建新的临时目录: ${framesDir.path}');

      // 保存原始文件路径用于动画预览
      _svgaFile = File(filePath);
      print('设置新的SVGA文件路径: ${_svgaFile?.path}');
      
      // 解析SVGA文件
      final parser = SVGAParser();
      final videoItem = await parser.decodeFromBuffer(
        await File(filePath).readAsBytes(),
      );
      print('SVGA文件解析完成');

      // 获取帧率和持续时间
      _fps = 30; // SVGA默认帧率为30fps
      _duration = (videoItem.images?.length ?? 0) / _fps;  // 使用图片数量计算持续时间
      print('FPS: $_fps, 持续时间: $_duration秒');

      // 创建临时列表存储帧
      final List<File> tempFrames = [];

      // 获取所有图片
      final images = videoItem.images;
      if (images != null) {
        print('开始提取帧图片，总数：${images.length}');
        var index = 0;
        for (var entry in images.entries) {
          if (entry.value.isNotEmpty) {
            try {
              // 解码图片数据
              final codec = await instantiateImageCodec(Uint8List.fromList(entry.value));
              final frame = await codec.getNextFrame();
              final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
              
              if (byteData != null) {
                final frameFile = File('${framesDir.path}/frame_$index.png');
                await frameFile.writeAsBytes(byteData.buffer.asUint8List());
                print('成功写入帧 $index 到文件: ${frameFile.path}');
                
                // 计算并累加内存占用
                _memoryUsage += (frame.image.width * frame.image.height * 4) / (1024 * 1024);  // 转换为MB
                print('当前帧内存占用: ${(frame.image.width * frame.image.height * 4) / (1024 * 1024)} MB');
                
                // 验证文件是否成功写入
                if (await frameFile.exists()) {
                  tempFrames.add(frameFile);
                  print('添加第 ${index + 1} 帧到临时数组，文件大小: ${await frameFile.length()} bytes');
                } else {
                  print('警告：帧文件未成功创建: ${frameFile.path}');
                }
                index++;
              }
            } catch (e) {
              print('处理帧 $index 时出错: $e');
            }
          }
        }
      }

      if (tempFrames.isEmpty) {
        print('未能从SVGA文件中提取到任何图片');
        await _clearState();
      } else {
        print('成功提取了 ${tempFrames.length} 帧图片');
        
        // 再次清除图片缓存，确保新图片能被加载
        imageCache.clear();
        imageCache.clearLiveImages();
        print('再次清空图片缓存');
        
        // 一次性更新所有帧
        _frames = List.from(tempFrames); // 创建新的列表以确保触发更新
        _currentFrameIndex = 0;  // 重置当前帧索引
        print('帧数组已更新，长度: ${_frames.length}');
        
        // 确保UI更新
        Future.microtask(() {
          notifyListeners();  // 在微任务中通知UI更新
          print('UI更新完成');
        });
      }
    } catch (e) {
      print('处理SVGA文件时出错: $e');
      print(e.toString());
      await _clearState();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVGA预览器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // 使用深色主题
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragDone: (details) async {
          final file = details.files.first;
          if (path.extension(file.path).toLowerCase() == '.svga') {
            // 先清空当前数据
            await Provider.of<SVGAViewModel>(context, listen: false)._clearState();
            
            // 处理新文件
            await Provider.of<SVGAViewModel>(context, listen: false)
                .processSVGAFile(file.path);
          }
        },
        onDragEntered: (details) {
          Provider.of<SVGAViewModel>(context, listen: false).setDragging(true);
        },
        onDragExited: (details) {
          Provider.of<SVGAViewModel>(context, listen: false).setDragging(false);
        },
        child: Stack(
          children: [
            Row(
              children: [
                // 左侧帧列表
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const FramesList(),
                ),
                // 右侧预览区域
                const Expanded(
                  child: PreviewArea(),
                ),
              ],
            ),
            // 拖拽提示遮罩
            Consumer<SVGAViewModel>(
              builder: (context, viewModel, child) {
                if (!viewModel.isDragging) return const SizedBox();
                return Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Text(
                      '释放以打开 SVGA 文件',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['svga'],
          );
          if (result != null) {
            // 先清空当前数据
            await Provider.of<SVGAViewModel>(context, listen: false)._clearState();
            
            // 处理新文件
            await Provider.of<SVGAViewModel>(context, listen: false)
                .processSVGAFile(result.files.single.path!);
          }
        },
        tooltip: '打开SVGA文件',
        child: const Icon(Icons.folder_open),
      ),
    );
  }
}

// 帧列表组件
class FramesList extends StatelessWidget {
  const FramesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SVGAViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.frames.isEmpty) {
          return const Center(
            child: Text('拖放SVGA文件到这里\n或点击右下角按钮打开文件'),
          );
        }

        return GridView.builder(
          key: ValueKey(viewModel.currentFileName),
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: viewModel.frames.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => viewModel.setCurrentFrameIndex(index),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: index == viewModel.currentFrameIndex
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade800,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.file(
                        viewModel.frames[index],
                        key: ValueKey('frame_${viewModel.currentFileName}_$index'),
                        fit: BoxFit.contain,
                        cacheWidth: null,
                        cacheHeight: null,
                        gaplessPlayback: false,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black45,
                      child: Text(
                        '帧 ${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 预览区域组件
class PreviewArea extends StatelessWidget {
  const PreviewArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SVGAViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          color: Colors.black,
          child: Column(
            children: [
              // 文件信息栏
              if (viewModel.currentFileName != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.movie_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.currentFileName!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '帧率: ${viewModel.fps.toStringAsFixed(1)} FPS  •  时长: ${viewModel.duration.toStringAsFixed(2)}秒  •  内存: ${viewModel.memoryUsage.toStringAsFixed(1)}MB',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '总帧数: ${viewModel.frames.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              // 上半部分：SVGA动画预览
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: viewModel.svgaFile == null
                        ? const Text('无预览内容')
                        : SVGAPreview(file: viewModel.svgaFile!),
                  ),
                ),
              ),
              // 下半部分：当前帧预览
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: viewModel.currentFrame == null
                          ? const Text('无预览内容')
                          : Image.file(
                              viewModel.currentFrame!,
                              key: ValueKey('preview_${viewModel.currentFileName}_${viewModel.currentFrameIndex}'),
                              fit: BoxFit.contain,
                              cacheWidth: null,
                              cacheHeight: null,
                              gaplessPlayback: false,
                            ),
                    ),
                    if (viewModel.currentFrame != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FutureBuilder<ui.Image>(
                                    future: ui.decodeImageFromList(viewModel.currentFrame!.readAsBytesSync()),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final image = snapshot.data!;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'frame_${viewModel.currentFrameIndex}.png',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '当前帧: ${viewModel.currentFrameIndex + 1}  •  尺寸: ${image.width} × ${image.height}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// SVGA预览组件
class SVGAPreview extends StatefulWidget {
  final File file;
  
  const SVGAPreview({super.key, required this.file});
  
  @override
  State<SVGAPreview> createState() => _SVGAPreviewState();
}

class _SVGAPreviewState extends State<SVGAPreview> with SingleTickerProviderStateMixin {
  late SVGAAnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _loadSVGA();
  }

  @override
  void didUpdateWidget(SVGAPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _loadSVGA();
    }
  }
  
  Future<void> _loadSVGA() async {
    try {
      _controller.reset();
      final parser = SVGAParser();
      final videoItem = await parser.decodeFromBuffer(
        await widget.file.readAsBytes(),
      );
      if (mounted) {
        _controller.videoItem = videoItem;
        _controller.repeat();
      }
    } catch (e) {
      print('加载SVGA文件失败: $e');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SVGAImage(_controller);
  }
}
