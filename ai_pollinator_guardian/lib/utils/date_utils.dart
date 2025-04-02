import 'package:intl/intl.dart';

class DateTimeUtils {
  // Format date as "Today", "Yesterday", or "Month Day, Year"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date); // "Jan 21, 2025"
    }
  }

  // Format time as "10:30 AM"
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time); // "10:30 AM"
  }

  // Format date and time as "Today at 10:30 AM" or "Jan 21, 2025 at 10:30 AM"
  static String formatRelativeDateAndTime(DateTime dateTime) {
    return '${formatRelativeDate(dateTime)} at ${formatTime(dateTime)}';
  }

  // Get the difference between two dates in a friendly format (e.g., "2 days ago")
  static String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    }
  }
}