import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../config/youversion_config.dart';

class YouVersionApiException implements Exception {
  final int? statusCode;
  final String message;

  const YouVersionApiException(this.message, {this.statusCode});

  @override
  String toString() => 'YouVersionApiException($statusCode): $message';
}

class YouVersionApiClient {
  YouVersionApiClient({
    http.Client? client,
    this.minGapBetweenRequests = const Duration(milliseconds: 350),
    this.maxRetries = 5,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration minGapBetweenRequests;
  final int maxRetries;

  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Random _rand = Random();

  Future<void> _throttle() async {
    final elapsed = DateTime.now().difference(_lastRequestAt);
    if (elapsed < minGapBetweenRequests) {
      await Future<void>.delayed(minGapBetweenRequests - elapsed);
    }
    _lastRequestAt = DateTime.now();
  }

  Future<Map<String, dynamic>> getPassage({
    required int versionId,
    required String usfmReference,
  }) async {
    if (!YouVersionConfig.isConfigured) {
      throw const YouVersionApiException(
          'YOUVERSION_APP_KEY is not configured');
    }

    final uri = Uri.parse(
      '${YouVersionConfig.baseUrl}/bibles/$versionId/passages/$usfmReference',
    );

    var attempt = 0;
    while (true) {
      attempt++;
      await _throttle();

      try {
        final response = await _client.get(
          uri,
          headers: {'X-YVP-App-Key': YouVersionConfig.appKey},
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
          throw YouVersionApiException(
            'Unexpected response format for $usfmReference: ${response.body}',
            statusCode: response.statusCode,
          );
        }

        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt > maxRetries) {
            throw YouVersionApiException(
              'Gave up after $attempt attempts for $usfmReference',
              statusCode: response.statusCode,
            );
          }

          final retryAfter = response.headers['retry-after'];
          final retrySeconds =
              retryAfter == null ? null : int.tryParse(retryAfter);
          if (retrySeconds != null) {
            await Future<void>.delayed(Duration(seconds: retrySeconds));
            continue;
          }

          await _backoff(attempt);
          continue;
        }

        throw YouVersionApiException(
          'Request failed for $usfmReference: ${response.body}',
          statusCode: response.statusCode,
        );
      } on YouVersionApiException {
        rethrow;
      } on Exception catch (error) {
        if (attempt > maxRetries) {
          throw YouVersionApiException(
            'Network error after $attempt attempts: $error',
          );
        }
        await _backoff(attempt);
      }
    }
  }

  Future<void> _backoff(int attempt) async {
    final baseDelay = pow(2, attempt).toDouble();
    final jitterMs = _rand.nextInt(300);
    await Future<void>.delayed(
      Duration(milliseconds: (baseDelay * 250).round() + jitterMs),
    );
  }

  void close() => _client.close();
}
