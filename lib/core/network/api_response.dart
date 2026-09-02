import 'api_exception.dart';

Map<String, dynamic> unwrapApiPayload(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  return json;
}

void requireApiSuccess(Map<String, dynamic> json, [String fallback = 'Request failed']) {
  if (json['success'] != true) {
    throw ApiException(apiErrorMessage(json) ?? fallback);
  }
}

List<Map<String, dynamic>> asJsonMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<Map<String, dynamic>> extractListFromPayload(
  Map<String, dynamic> payload, {
  List<String> keys = const [
    'items',
    'appointments',
    'conversations',
    'messages',
    'checkIns',
    'check_ins',
    'doctors',
    'slots',
    'availability',
    'reminders',
    'notifications',
  ],
}) {
  for (final key in keys) {
    final list = asJsonMapList(payload[key]);
    if (list.isNotEmpty) return list;
  }

  if (payload['data'] is List) {
    return asJsonMapList(payload['data']);
  }

  return const [];
}

String readString(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

bool readBool(Map<String, dynamic> json, List<String> keys, {bool fallback = false}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
  }
  return fallback;
}

int? readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
  }
  return null;
}

double? readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}

List<int> readIntList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is! List) continue;
    final numbers = value
        .map((item) {
          if (item is int) return item;
          if (item is num) return item.toInt();
          return int.tryParse(item.toString());
        })
        .whereType<int>()
        .toList();
    if (numbers.isNotEmpty) return numbers;
  }
  return const [];
}

Map<String, dynamic> clientJsonFromPayload(Map<String, dynamic> payload) {
  final client = payload['client'];
  if (client is Map<String, dynamic>) {
    return client;
  }

  if (payload.containsKey('id') && payload.containsKey('email')) {
    return payload;
  }

  throw const ApiException('Invalid client data in response');
}

String? apiErrorMessage(Map<String, dynamic> json) {
  final error = json['error'] ?? json['message'];
  if (error is String && error.isNotEmpty) {
    return error;
  }

  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['error'] ?? data['message'];
    if (nested is String && nested.isNotEmpty) {
      return nested;
    }
  }

  return null;
}
