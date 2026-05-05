/// Helper to ensure dates from API are parsed correctly as UTC and converted to local time
DateTime parseUtcDate(String dateStr) {
  if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
    dateStr += 'Z';
  }
  return DateTime.parse(dateStr).toLocal();
}
