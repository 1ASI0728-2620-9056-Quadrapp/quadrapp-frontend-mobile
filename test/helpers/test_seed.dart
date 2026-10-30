import 'dart:io';

import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';

/// Los datos de prueba de `assets/mocks/seed.json`, leídos del disco (las
/// pruebas corren desde la raíz del proyecto). Cada mundo arma sus propios
/// objetos a partir de ellos, así que se pueden compartir.
final MockSeed testSeed = MockSeed.parse(
  File(MockSeed.assetPath).readAsStringSync(),
);
