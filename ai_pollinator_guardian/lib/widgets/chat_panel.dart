import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/providers/chat_provider.dart';
import 'package:ai_pollinator_guardian/widgets/message_bubble.dart';
import 'package:ai_pollinator_guardian/widgets/chat_input.dart';

class ChatPanel extends StatefulWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetCtl;
  
  const ChatPanel({
    required this.scrollController,
    required this.sheetCtl,
    super.key,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> with WidgetsBindingObserver {
  final _inputCtl = TextEditingController();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardShowing = bottom > 0;
    
    // 只在键盘状态变化时执行操作
    if (keyboardShowing != _keyboardVisible) {
      setState(() {
        _keyboardVisible = keyboardShowing;
      });
      
      if (keyboardShowing) {
        // 键盘出现 -> 把 sheet 拉到 90%
        widget.sheetCtl.animateTo(
          0.9,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        
        // 滚动到底部确保输入框可见
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        // 键盘消失 -> 将sheet恢复到原来大小（可选）
        // widget.sheetCtl.animateTo(
        //   0.55,
        //   duration: const Duration(milliseconds: 250),
        //   curve: Curves.easeOut,
        // );
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    // 获取键盘高度
    final kb = MediaQuery.of(ctx).viewInsets.bottom;
    final chat = ctx.watch<ChatProvider>();

    return SafeArea(
      top: false,
      bottom: false, // 让SafeArea不处理底部，我们手动添加padding
      child: Column(
        children: [
          Container(  // 小手柄
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 聊天消息列表，使用Expanded确保它占用所有可用空间
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chat.messages.length,
              itemBuilder: (_, i) => MessageBubble(message: chat.messages[i]),
            ),
          ),
          // 输入框，添加键盘高度的padding以避免遮挡
          Padding(
            padding: EdgeInsets.only(bottom: kb > 0 ? kb : 0),
            child: ChatInput(
              controller: _inputCtl,
              onSend: (text) {
                chat.sendMessage(text);
                _inputCtl.clear();
                
                // 发送后滚到底
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (widget.scrollController.hasClients) {
                    widget.scrollController.animateTo(
                      widget.scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}