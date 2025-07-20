import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

class SVGAControlBar extends StatelessWidget {
  final SVGAViewModel viewModel;
  final SVGAAnimationController controller;

  const SVGAControlBar({super.key, required this.viewModel, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,  // 使用 Scaffold 的默认背景色
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          showValueIndicator: ShowValueIndicator.always,
          trackHeight: 2,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, pressedElevation: 4),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      return Text(
                        '当前帧: ${controller.currentFrame + 1} / ${controller.frames}', 
                        style: const TextStyle(fontSize: 12)
                      );
                    }
                  ),
                  const Spacer(),
                  _PlayButton(controller: controller,),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(left: 3, right: 3),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Slider(
                    activeColor: Colors.deepPurpleAccent.shade200,
                    min: 0,
                    max: controller.frames.toDouble(),
                    value: controller.currentFrame.toDouble(),
                    // label: '${controller.currentFrame}',
                    onChanged: (v) {
                      if (controller.isAnimating == true) {
                        controller.stop();
                      }
                      // 📌 当划到1.0时会看不到最后一帧的画面，松手才看到，而第三方demo却没事，不知道为啥，只好弄成无限接近1，暂时先这么处理吧😫
                      controller.value = min(v / controller.frames, 0.999999999); 
                      // print('v: $v, currentFrame: ${controller.currentFrame}, frames: ${controller.frames}, lowerBound: ${controller.lowerBound}, upperBound: ${controller.upperBound}, value: ${controller.value}');
                    },
                  );
                }
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  const Text('允许绘制溢出:', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: viewModel.allowDrawingOverflow,
                      onChanged: viewModel.setAllowDrawingOverflow,
                      activeColor: Colors.deepPurpleAccent.shade200,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// 
/// 📒 笔记：一般情况下，你要「在 StatefulWidget 里用 AnimatedBuilder」，而不是用 AnimatedBuilder 去包整个 StatefulWidget。
/// 
/// ✅ AnimatedBuilder 放在 StatefulWidget 的 build 里
/// - State 里管理 AnimationController 的生命周期
/// - AnimatedBuilder 只负责在 build 里局部刷新，child 部分是缓存，不会重新构建
/// 
/// ⚡️ 如果在 StatefulWidget 外面包 AnimatedBuilder
/// - AnimatedBuilder 每一帧重建整个 MyStatefulWidget
/// - MyStatefulWidget 的所有状态、生命周期都可能重新走一遍（看写法）
/// - 完全丢失了 StatefulWidget 的意义
/// 
/// 📌 结论
/// ✅ 你应该在 StatefulWidget 里用 AnimatedBuilder 来「驱动部分 UI 的变化」
/// ✅ 而不是用 AnimatedBuilder 去包一个 StatefulWidget 让它整体每帧刷新
/// 
class _PlayButton extends StatefulWidget {
  final SVGAAnimationController controller;

  const _PlayButton({required this.controller});

  @override
  State<_PlayButton> createState() => __PlayButtonState();
}

class __PlayButtonState extends State<_PlayButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          return IconButton(
            onPressed: () {
              if (widget.controller.isAnimating == true) {
                widget.controller.stop();
              } else {
                if (widget.controller.isCompleted == true) {
                  widget.controller.reset();
                }
                widget.controller.repeat();
              }
              setState(() {});
            },
            icon: Icon(widget.controller.isAnimating ? Icons.pause : Icons.play_arrow),
            iconSize: 17,
            padding: EdgeInsets.zero,
            color: Colors.white,
          );
        }
      ),
    );
  }
}