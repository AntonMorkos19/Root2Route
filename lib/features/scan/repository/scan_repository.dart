import 'dart:io';

import 'package:dio/dio.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/features/scan/models/plant_analysis_response_model.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Repository that wraps the AI model-analysis endpoint.
///
/// Endpoint: POST /api/v1/model-analysis/analyze
/// Body:     multipart/form-data  — field name `ImageFile`
class ScanRepository {
  late final Dio _dio;

  ScanRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Uploads [imageFile] to the AI analysis endpoint and returns a typed
  /// [PlantAnalysisResponseModel].
  ///
  /// Throws a [ScanException] if the request fails or the server returns an
  /// error payload.
  Future<PlantAnalysisResponseModel> analyzePlantImage(File imageFile) async {
    try {
      // Build the filename from the path — works on both Android and iOS
      final String fileName =
          imageFile.path.split(Platform.pathSeparator).last.split('/').last;

      final FormData formData = FormData.fromMap({
        'ImageFile': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      print('[ScanRepository] Sending image: $fileName');

      final response = await _dio.post(
        '/model-analysis/analyze',
        data: formData,
        options: Options(
          validateStatus: (status) => status != null && status <= 500,
          headers: {'accept': '*/*'},
        ),
      );

      print('[ScanRepository] Raw response: ${response.data}');

      final respBody = response.data;

      if (respBody is! Map<String, dynamic>) {
        throw ScanException('Unexpected response format from server.');
      }

      // Treat HTTP 4xx or an explicit succeeded:false as failure
      final succeededRaw =
          respBody['succeeded'] ?? respBody['success'] ?? respBody['isSuccess'];
      final succeeded =
          succeededRaw == true ||
          succeededRaw == 1 ||
          (response.statusCode != null && response.statusCode! < 300);

      if (!succeeded) {
        final msg =
            respBody['message']?.toString() ??
            'Analysis failed (status ${response.statusCode})';
        throw ScanException(msg);
      }

      return PlantAnalysisResponseModel.fromJson(respBody);
    } on ScanException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map ? data['message']?.toString() : null) ??
          e.message ??
          'Network error. Please check your connection.';
      throw ScanException(msg);
    } catch (e) {
      throw ScanException('Unexpected error: $e');
    }
  }
}

/// Typed exception for scan / analysis failures.
class ScanException implements Exception {
  final String message;
  const ScanException(this.message);

  @override
  String toString() => 'ScanException: $message';
}
