import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/problem_report_dto.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto de los reportes de problema (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class ProblemReportRemoteDataSource {
  /// `POST /device-incidents`.
  Future<ProblemReceiptDto> report(ProblemReportRequestDto request);
}

/// `POST /device-incidents` (docs/07).
class ProblemReportHttpDataSource implements ProblemReportRemoteDataSource {
  const ProblemReportHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ProblemReceiptDto> report(ProblemReportRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/device-incidents',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El reporte registrado no es un objeto.');
    }
    return ProblemReceiptDto.fromJson(data);
  }
}
