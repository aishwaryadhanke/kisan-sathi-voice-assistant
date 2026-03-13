// lib/recent_responses_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// This is the type your main.dart expects 👇
class RecentResponse {
  final String query;
  final String response;
  final DateTime timestamp;

  RecentResponse({
    required this.query,
    required this.response,
    required this.timestamp,
  });

  // 👇 This makes item.reply work in main.dart
  String get reply => response;

  Map<String, dynamic> toJson() => {
        'query': query,
        'response': response,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentResponse.fromJson(Map<String, dynamic> json) {
    return RecentResponse(
      query: json['query'] as String? ?? '',
      response: json['response'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}


class RecentResponsesStorage {
  static const String _storageKey = 'recent_responses';

  /// ✅ This is the one used in main.dart:
  /// `RecentResponsesStorage.getRecentResponses()`
  static Future<List<RecentResponse>> getRecentResponses() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];

    return stored
        .map((s) {
          try {
            final map = jsonDecode(s) as Map<String, dynamic>;
            return RecentResponse.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentResponse>()
        .toList();
  }

  /// ✅ Call this after every successful query in main.dart
  static Future<void> addResponse({
    required String query,
    required String response,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    final item = RecentResponse(
      query: query,
      response: response,
      timestamp: DateTime.now(),
    );

    // Newest at top
    existing.insert(0, jsonEncode(item.toJson()));

    // Keep only latest 50
    if (existing.length > 50) {
      existing.removeRange(50, existing.length);
    }

    await prefs.setStringList(_storageKey, existing);
  }

  /// Optional: clear all recent responses
  static Future<void> clearRecentResponses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
