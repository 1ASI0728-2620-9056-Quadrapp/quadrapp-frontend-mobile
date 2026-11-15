import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Lecturas defensivas de las respuestas del backend: un campo con otro tipo
/// es un `ParseException` (→ `ParseFailure`), nunca un error de tipos suelto.
Map<String, dynamic> backendObject(Object? data, String what) {
  if (data is! Map<String, dynamic>) {
    throw ParseException('$what no es un objeto JSON.');
  }
  return data;
}

/// Una lista de objetos JSON.
List<Map<String, dynamic>> backendObjects(Object? data, String what) {
  if (data is! List<dynamic>) {
    throw ParseException('$what no es un arreglo.');
  }
  return [for (final item in data) backendObject(item, what)];
}

/// Un número entero obligatorio.
int backendInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! num) throw ParseException('El campo $field no es válido.');
  return value.toInt();
}
