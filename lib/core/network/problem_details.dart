/// Error con formato RFC 9457 (`application/problem+json`):
/// `{ type, title, status, detail, errors? }`. Se lee de forma tolerante: una
/// respuesta de error que no sea un JSON válido no debe romper el manejo.
class ProblemDetails {
  const ProblemDetails({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.errors = const {},
    this.retryAfterSec,
  });

  /// Devuelve `null` si [data] no es un objeto JSON.
  static ProblemDetails? tryParse(Object? data) {
    if (data is! Map<dynamic, dynamic>) return null;
    final rawErrors = data['errors'];
    final errors = <String, List<String>>{};
    if (rawErrors is Map<dynamic, dynamic>) {
      for (final entry in rawErrors.entries) {
        final value = entry.value;
        errors['${entry.key}'] = value is List
            ? [for (final item in value) '$item']
            : ['$value'];
      }
    }
    final retry = data['retryAfterSec'];
    return ProblemDetails(
      type: data['type'] as String?,
      title: data['title'] as String?,
      status: data['status'] is int ? data['status'] as int : null,
      detail: data['detail'] as String?,
      errors: errors,
      retryAfterSec: retry is num ? retry.toInt() : null,
    );
  }

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final Map<String, List<String>> errors;

  /// Solo en el 429 de OTP (`{ retryAfterSec }`).
  final int? retryAfterSec;
}
