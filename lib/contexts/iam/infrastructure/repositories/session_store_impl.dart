import 'dart:convert';

import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

/// Guarda la sesión en el dispositivo: el **refresh token solo en el almacén
/// seguro** y el usuario (rol e institución) en el `KeyValueStore`, bajo el
/// prefijo `user.`. Nada de esto contiene el token de acceso.
///
/// Si lo guardado está dañado (JSON ilegible, token vacío), se trata como que
/// no hay sesión y se limpia.
class SessionStoreImpl implements SessionStore, Resettable {
  const SessionStoreImpl({
    required this._values,
    required this._secrets,
    required this._mapper,
  });

  final KeyValueStore _values;
  final SecureStore _secrets;
  final IamMapper _mapper;

  static const _userKey = '${StoreKeys.user}session';
  static const _refreshKey = 'refreshToken';

  @override
  Future<StoredSession?> read() async {
    final rawUser = await _values.getString(_userKey);
    final rawToken = await _secrets.read(_refreshKey);
    if (rawUser == null || rawToken == null) return null;
    try {
      final token = RefreshToken.create(rawToken).valueOrNull;
      final user = UserDto.fromJson(
        jsonDecode(rawUser) as Map<String, dynamic>,
      );
      if (token == null) throw const FormatException('token vacío');
      return StoredSession(
        session: _mapper.toSession(user),
        refreshToken: token,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(StoredSession session) async {
    await _secrets.write(_refreshKey, session.refreshToken.value);
    await _values.setString(
      _userKey,
      jsonEncode(_mapper.toUserDto(session.session).toJson()),
    );
  }

  @override
  Future<void> clear() async {
    await _secrets.delete(_refreshKey);
    await _values.remove(_userKey);
  }

  @override
  Future<void> reset() => clear();
}
