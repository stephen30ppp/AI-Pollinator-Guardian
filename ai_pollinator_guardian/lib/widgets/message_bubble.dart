import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/models/chat_message_model.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // 添加Lottie导入

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  
  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) 
              const BotInfo(),
            
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? const Color(0xFF0D47A1) : Colors.black87,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}

class BotInfo extends StatelessWidget {
  const BotInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 1),
            ),
            clipBehavior: Clip.antiAlias, // 添加裁剪以确保动画在圆形内显示
            child: Lottie.asset(
              'assets/animations/bee_guide.json',
              fit: BoxFit.cover,
              animate: true,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Bee Guide',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}