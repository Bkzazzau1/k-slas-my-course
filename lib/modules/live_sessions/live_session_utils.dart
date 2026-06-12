String liveSessionDayTimeRange(DateTime start, DateTime end) {
  return '${_weekDay(start.weekday)} · ${_time(start)} - ${_time(end)}';
}

String liveSessionDateTime(DateTime value) {
  return '${_month(value.month)} ${value.day}, ${value.year} · ${_time(value)}';
}

String liveSessionMinutesLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (remain == 0) return '${hours}h';
  return '${hours}h ${remain}m';
}

String liveSessionShortDate(DateTime value) {
  return '${_month(value.month)} ${value.day}';
}

String _time(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _weekDay(int day) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final index = day <= 0 ? 0 : (day > 7 ? 6 : day - 1);
  return days[index];
}

String _month(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final index = month <= 0 ? 0 : (month > 12 ? 11 : month - 1);
  return months[index];
}
