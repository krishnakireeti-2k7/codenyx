import 'package:codenyx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  final MessageModel message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser
        ? AppTheme.accentPrimary.withValues(alpha: 0.18)
        : AppTheme.surfaceLight.withValues(alpha: 0.92);
    final alignment =
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isCurrentUser
                  ? AppTheme.accentPrimary.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              Text(
                message.userName,
                style: AppTheme.metaText.copyWith(
                  color: isCurrentUser
                      ? AppTheme.accentPrimary
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                message.message,
                style: AppTheme.cardBody.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                _formatTime(message.createdAt),
                style: AppTheme.metaText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
