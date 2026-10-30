import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';

/// El token de acceso solo en memoria: no se escribe en ningún almacén.
class InMemoryAccessTokenHolder implements AccessTokenHolder, Resettable {
  AccessToken? _current;

  @override
  AccessToken? get current => _current;

  @override
  void replace(AccessToken token) => _current = token;

  @override
  void clear() => _current = null;

  @override
  Future<void> reset() async => clear();
}
