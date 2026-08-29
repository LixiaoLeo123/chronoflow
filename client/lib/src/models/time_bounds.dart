DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) =>
    startOfDay(value).add(const Duration(days: 1));

DateTime startOfWeek(DateTime value) {
  final day = startOfDay(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime endOfWeek(DateTime value) =>
    startOfWeek(value).add(const Duration(days: 7));

bool spansMidnight(DateTime start, DateTime end) =>
    startOfDay(start) !=
    startOfDay(end.subtract(const Duration(microseconds: 1)));
