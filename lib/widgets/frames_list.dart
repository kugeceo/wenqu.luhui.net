import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/svga_view_model.dart';
import 'package:flutter/cupertino.dart';

class FramesList extends StatelessWidget {
  const FramesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SVGAViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            Expanded(
              child: viewModel.frames.isEmpty
                  ? const Center(
                      child: Text('拖放SVGA文件到这里\n或点击右下角按钮打开文件'),
                    )
                  : GridView.builder(
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
                                    '图 ${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // 开关选项栏
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,  // 添加半透明黑色背景
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text('显示边框:', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: viewModel.showBorder,
                      onChanged: viewModel.setShowBorder,
                      activeColor: Colors.blue.shade200,
                    ),
                  ),
                ],
              ),
            ),
            // 背景选项栏
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,  // 添加半透明黑色背景
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('背景颜色:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ColorButton(
                        color: Colors.black,
                        isSelected: viewModel.backgroundColor == Colors.black,
                        onTap: () => viewModel.setBackgroundColor(Colors.black),
                      ),
                      _ColorButton(
                        color: Colors.white,
                        isSelected: viewModel.backgroundColor == Colors.white,
                        onTap: () => viewModel.setBackgroundColor(Colors.white),
                      ),
                      _ColorButton(
                        color: Colors.grey,
                        isSelected: viewModel.backgroundColor == Colors.grey,
                        onTap: () => viewModel.setBackgroundColor(Colors.grey),
                      ),
                      _ColorButton(
                        color: Colors.blue,
                        isSelected: viewModel.backgroundColor == Colors.blue,
                        onTap: () => viewModel.setBackgroundColor(Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade800,
            width: 2,
          ),
        ),
      ),
    );
  }
} 