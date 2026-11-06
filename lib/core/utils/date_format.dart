import 'package:intl/intl.dart';

class AppDateFormat {
  const AppDateFormat._();

  static final DateFormat _dayTime = DateFormat('d MMM, HH:mm', 'ru');
  static final DateFormat _time = DateFormat('HH:mm', 'ru');

  static String dayTime(DateTime value) => _dayTime.format(value.toLocal());

  static String time(DateTime value) => _time.format(value.toLocal());

  static String relative(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'только что';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    }
    if (difference.inHours < 24 && now.day == local.day) {
      return 'сегодня, ${time(local)}';
    }
    if (difference.inDays < 2) {
      return 'вчера, ${time(local)}';
    }
    return dayTime(local);
  }

  static String sla(DateTime value) {
    final difference = value.toLocal().difference(DateTime.now());
    if (difference.isNegative) {
      return 'просрочен на ${_duration(-difference)}';
    }
    return 'осталось ${_duration(difference)}';
  }

  static String _duration(Duration duration) {
    if (duration.inHours >= 24) {
      return '${duration.inDays} д';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} ч ${duration.inMinutes.remainder(60)} мин';
    }
    return '${duration.inMinutes} мин';
  }
}
