import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';
import 'package:svga_previewer/widgets/animation_preview.dart';
import 'package:svga_previewer/widgets/frame_preview.dart';
import 'package:svga_previewer/widgets/frames_list.dart';
import 'package:svga_previewer/widgets/svga_info_bar.dart';
import 'package:svga_previewer/widgets/svga_preview.dart';
import 'package:svgaplayer_flutter/player.dart';

class JPMainScreen extends StatefulWidget {
  const JPMainScreen({super.key});

  @override
  State<JPMainScreen> createState() => _JPMainScreenState();
}

class _JPMainScreenState extends State<JPMainScreen> with SingleTickerProviderStateMixin {
  late SVGAAnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
  }

  @override
  void dispose() {
    // ✅ 正确地在父组件中释放controller
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              child: FramesList(controller: _controller),
            ),
            // 右侧预览区域
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    // 文件信息栏
                    const SVGAInfoBar(),
                    // 动画播放区域
                    Expanded(child: AnimationPreview(controller: _controller),),
                    // 分隔线
                    Container(height: 1, color: Colors.grey.shade800,),
                    // 图片预览区域
                    const Expanded( child: FramePreview(),),
                  ],
                ),
              ),
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
    );
  }
}