List<Map<String, dynamic>> readListPayload(Object? data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  if (data is Map<String, dynamic>) {
    final results = data['results'];
    if (results is List) {
      return results.whereType<Map<String, dynamic>>().toList(growable: false);
    }
  }
  return const [];
}
