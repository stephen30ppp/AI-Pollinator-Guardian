import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/widgets/chat_panel.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/providers/chat_provider.dart';

/// 可拖动的聊天悬浮按钮，点击后显示聊天面板
class ChatFab extends StatefulWidget {
  const ChatFab({super.key});
  @override _ChatFabState createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab> with SingleTickerProviderStateMixin {
  Offset pos = const Offset(20, 450);  // 将y坐标从520改为450，向上移动70像素
  bool _showTip = true;
  late final AnimationController _tipCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    _tipCtl.forward();                    // slide in
    // auto‑fade after 5 s
    Future.delayed(const Duration(seconds: 5), () => _dismissTip());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // rebuild when a new chat starts, show tip again
    context.watch<ChatProvider>().sessionId;
  }

  void _dismissTip() {
    if (_showTip) {
      setState(() => _showTip = false);
      _tipCtl.reverse();                 // slide out
    }
  }

  @override
  void dispose() {
    _tipCtl.dispose();
    super.dispose();
  }
  
  void _openPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetCtl = DraggableScrollableController();
        return DraggableScrollableSheet(
          controller: sheetCtl,
          initialChildSize: .55,
          maxChildSize: .9,
          minChildSize: .3,
          expand: false,
          builder: (innerCtx, scrollCtl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ChatPanel(
              scrollController: scrollCtl,
              sheetCtl: sheetCtl,
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    _showTip = true;  // reset each rebuild
    
    return Stack(
      children: [
        Positioned(
          left: pos.dx, 
          top: pos.dy,
          child: Draggable(
            feedback: _bubble(), 
            childWhenDragging: const SizedBox.shrink(),
            onDraggableCanceled: (_, offset) => setState(() => pos = offset),
            child: GestureDetector(
              onTap: () {
                _dismissTip();               // hide balloon when opening chat
                _openPanel();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _bubble(),
                  if (_showTip)
                    Positioned(
                      left: -10,              // adjust to align nicely
                      bottom: 70,             // sits on top of bee
                      child: _tipBubble(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _bubble() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ① circular yellow base
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF176),        // bee yellow
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
        ),
        // ② Lottie bee, slightly bigger for overlap
        Positioned.fill(
          child: Lottie.asset(
            'assets/animations/bee.json',
            repeat: true,
            animate: true,
            fit: BoxFit.contain,
          ),
        ),
        // ③ tiny chat badge bottom‑right
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble, size: 14, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _tipBubble() {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _tipCtl, curve: Curves.easeOut),
      axisAlignment: -1,       // grow from top
      child: GestureDetector(
        onTap: _dismissTip,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4), // small gap above bee
            padding: const EdgeInsets.all(10),
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: const Text(
              "I'm Bee Guide –\ntell me what you want to know!",
              style: TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ),
      ),
    );
  }
}