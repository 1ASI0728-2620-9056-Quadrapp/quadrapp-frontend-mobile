// US13, US14
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_preferences.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/eta_preferences_store.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Las preferencias del ETA (modo automático y tráfico). Si no se pueden leer,
/// los valores por defecto.
class GetEtaPreferences implements UseCase<EtaPreferences, NoParams> {
  const GetEtaPreferences(this._store);

  final EtaPreferencesStore _store;

  @override
  Future<Result<EtaPreferences>> call(NoParams params) async {
    final result = await guardResult(_store.read);
    return result.isSuccess ? result : const Success(EtaPreferences());
  }
}

/// Guarda las preferencias del ETA.
class SaveEtaPreferences implements UseCase<void, EtaPreferences> {
  const SaveEtaPreferences(this._store);

  final EtaPreferencesStore _store;

  @override
  Future<Result<void>> call(EtaPreferences params) =>
      guardResult(() => _store.save(params));
}
