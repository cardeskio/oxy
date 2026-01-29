import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
  static final _compactCurrencyFormat = NumberFormat.compactCurrency(symbol: 'KES ', decimalDigits: 0);
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _shortDateFormat = DateFormat('MMM d');
  static final _monthYearFormat = DateFormat('MMMM yyyy');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');
  static final _dayOfWeekFormat = DateFormat('EEEE');

  static String currency(double amount) => _currencyFormat.format(amount);
  static String compactCurrency(double amount) => _compactCurrencyFormat.format(amount);
  
  // Always convert to local time for display
  static String date(DateTime date) => _dateFormat.format(date.toLocal());
  static String shortDate(DateTime date) => _shortDateFormat.format(date.toLocal());
  static String monthYear(DateTime date) => _monthYearFormat.format(date.toLocal());
  static String time(DateTime date) => _timeFormat.format(date.toLocal());
  static String dateTime(DateTime date) => _dateTimeFormat.format(date.toLocal());
  static String dayOfWeek(DateTime date) => _dayOfWeekFormat.format(date.toLocal());
  
  static String phone(String phone) {
    if (phone.startsWith('+254')) {
      return '+254 ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  static String relativeDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes < 2) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(localDate);
  }

  static String daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    
    if (diff < 0) return '${-diff} days overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }
}
