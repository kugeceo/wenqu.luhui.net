import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';

class ToggleBorderBar extends StatelessWidget {
  final SVGAViewModel viewModel;

  const ToggleBorderBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,  // 使用 Scaffold 的默认背景色
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
    );
  }
}