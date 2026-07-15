import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../screens/analysis_screen.dart';

class PdfUploadResponse {
  final String status;
  final String filename;
  final String? contentType;
  final int sizeBytes;
  final String message;
  final int? rawTextLength;
  final OFPAnalysisData? analysisData;

  const PdfUploadResponse({
    required this.status,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.message,
    this.rawTextLength,
    this.analysisData,
  });

  factory PdfUploadResponse.fromJson(Map<String, dynamic> json) {
    return PdfUploadResponse(
      status: json['status'] as String? ?? 'unknown',
      filename: json['filename'] as String? ?? '',
      contentType: json['content_type'] as String?,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      rawTextLength: json['raw_text_length'] as int?,
      analysisData: OFPAnalysisData.fromAnalyzeResponseJson(json),
    );
  }
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://perception-api-745432017149.europe-west1.run.app',
  );

  static Future<PdfUploadResponse> uploadPdf(File file) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 180),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _decodeJsonObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail']?.toString();
      throw ApiException(
        detail == null || detail.isEmpty
            ? 'Upload failed with status ${response.statusCode}.'
            : detail,
      );
    }

    return PdfUploadResponse.fromJson(decoded);
  }

  static Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected a JSON object response.');
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
