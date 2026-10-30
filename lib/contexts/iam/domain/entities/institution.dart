import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La institución (universidad) a la que pertenece el usuario. Todo en
/// Quadrapp pertenece a una institución (multi-tenant).
class Institution extends Equatable {
  const Institution({required this.id, required this.name});

  final InstitutionId id;
  final String name;

  @override
  List<Object?> get props => [id.value, name];
}
