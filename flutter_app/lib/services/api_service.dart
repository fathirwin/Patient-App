import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/patient_data.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // GANTI dengan alamat server backend-mu jika perlu.
  // - Chrome / Flutter Web    -> http://localhost:8000 (otomatis, lihat _defaultBaseUrl)
  // - Emulator Android bawaan -> http://10.0.2.2:8000
  // - HP fisik / device lain  -> IP LAN komputer, mis. http://192.168.1.10:8000
  static String baseUrl = _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  static Future<PredictionResult> predict(PatientData data) async {
    final uri = Uri.parse('$baseUrl/predict');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return PredictionResult.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw ApiException(body['detail']?.toString() ?? 'Terjadi kesalahan pada server');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Tidak bisa terhubung ke server. Pastikan backend aktif dan alamat server benar.',
      );
    }
  }
}