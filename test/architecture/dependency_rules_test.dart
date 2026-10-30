// Test de arquitectura (docs/04): debe estar siempre en verde.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_rules.dart';

typedef _Case = (String from, String uri, {bool allowed});

const _flutterMaterial = 'package:flutter/material.dart';
const _occ = 'contexts/occupancy';
const _pkg = 'package:quadrapp_mobile';

const List<_Case> _cases = [
  // --- domain ---
  ('$_occ/domain/entities/a.dart', '../value_objects/b.dart', allowed: true),
  ('$_occ/domain/a.dart', 'package:equatable/equatable.dart', allowed: true),
  ('$_occ/domain/a.dart', 'dart:core', allowed: true),
  ('$_occ/domain/a.dart', '$_pkg/core/identifiers/lot_id.dart', allowed: true),
  ('$_occ/domain/a.dart', '$_pkg/core/result/result.dart', allowed: true),
  ('$_occ/domain/a.dart', '$_pkg/core/error/failure.dart', allowed: true),
  ('$_occ/domain/a.dart', '$_pkg/core/time/clock.dart', allowed: true),
  ('$_occ/domain/a.dart', _flutterMaterial, allowed: false),
  ('$_occ/domain/a.dart', 'dart:ui', allowed: false),
  ('$_occ/domain/a.dart', 'package:dio/dio.dart', allowed: false),
  (
    '$_occ/domain/a.dart',
    'package:flutter_bloc/flutter_bloc.dart',
    allowed: false,
  ),
  ('$_occ/domain/a.dart', 'package:get_it/get_it.dart', allowed: false),
  (
    '$_occ/domain/a.dart',
    '$_pkg/core/network/dio_factory.dart',
    allowed: false,
  ),
  ('$_occ/domain/a.dart', '$_pkg/$_occ/application/b.dart', allowed: false),
  ('$_occ/domain/a.dart', '../infrastructure/b.dart', allowed: false),
  ('$_occ/domain/a.dart', '$_pkg/$_occ/presentation/b.dart', allowed: false),
  (
    '$_occ/domain/a.dart',
    '$_pkg/contexts/prediction/prediction.dart',
    allowed: false,
  ),
  (
    '$_occ/domain/a.dart',
    '$_pkg/contexts/prediction/domain/b.dart',
    allowed: false,
  ),
  ('$_occ/domain/a.dart', '$_pkg/app/di/injector.dart', allowed: false),
  ('$_occ/domain/a.dart', '$_pkg/composition/x/y.dart', allowed: false),

  // --- application ---
  ('$_occ/application/a.dart', '../domain/b.dart', allowed: true),
  ('$_occ/application/usecases/a.dart', '../b.dart', allowed: true),
  (
    '$_occ/application/a.dart',
    '$_pkg/core/network/dio_factory.dart',
    allowed: true,
  ),
  (
    '$_occ/application/a.dart',
    '$_pkg/contexts/prediction/prediction.dart',
    allowed: true,
  ),
  ('$_occ/application/a.dart', _flutterMaterial, allowed: false),
  (
    '$_occ/application/a.dart',
    'package:flutter_bloc/flutter_bloc.dart',
    allowed: false,
  ),
  ('$_occ/application/a.dart', 'dart:ui', allowed: false),
  // Extra: get_it solo en app/di.
  ('$_occ/application/a.dart', 'package:get_it/get_it.dart', allowed: false),
  ('$_occ/application/a.dart', '../infrastructure/b.dart', allowed: false),
  ('$_occ/application/a.dart', '../presentation/b.dart', allowed: false),
  (
    '$_occ/application/a.dart',
    '$_pkg/contexts/prediction/domain/b.dart',
    allowed: false,
  ),
  ('$_occ/application/a.dart', '$_pkg/app/di/injector.dart', allowed: false),

  // --- infrastructure ---
  ('$_occ/infrastructure/a.dart', '../domain/b.dart', allowed: true),
  ('$_occ/infrastructure/a.dart', 'package:dio/dio.dart', allowed: true),
  (
    '$_occ/infrastructure/a.dart',
    '$_pkg/core/network/dio_factory.dart',
    allowed: true,
  ),
  ('$_occ/infrastructure/a.dart', '../application/b.dart', allowed: false),
  ('$_occ/infrastructure/a.dart', '../presentation/b.dart', allowed: false),
  (
    '$_occ/infrastructure/a.dart',
    '$_pkg/contexts/prediction/prediction.dart',
    allowed: false,
  ),
  (
    '$_occ/infrastructure/a.dart',
    '$_pkg/contexts/prediction/domain/b.dart',
    allowed: false,
  ),
  ('$_occ/infrastructure/a.dart', '$_pkg/app/di/injector.dart', allowed: false),

  // --- presentation ---
  ('$_occ/presentation/a.dart', '../application/b.dart', allowed: true),
  ('$_occ/presentation/a.dart', '../domain/b.dart', allowed: true),
  ('$_occ/presentation/a.dart', _flutterMaterial, allowed: true),
  (
    '$_occ/presentation/a.dart',
    'package:flutter_bloc/flutter_bloc.dart',
    allowed: true,
  ),
  (
    '$_occ/presentation/a.dart',
    '$_pkg/core/design_system/qa_button.dart',
    allowed: true,
  ),
  (
    '$_occ/presentation/a.dart',
    '$_pkg/contexts/prediction/prediction.dart',
    allowed: true,
  ),
  ('$_occ/presentation/a.dart', '../infrastructure/b.dart', allowed: false),
  (
    '$_occ/presentation/a.dart',
    '$_pkg/contexts/prediction/application/b.dart',
    allowed: false,
  ),
  (
    '$_occ/presentation/a.dart',
    '$_pkg/app/theme/qa_colors.dart',
    allowed: false,
  ),
  ('$_occ/presentation/a.dart', '$_pkg/composition/x/y.dart', allowed: false),

  // --- archivo público del contexto ---
  ('$_occ/occupancy.dart', 'contexts/occupancy/domain/b.dart', allowed: false),
  ('$_occ/occupancy.dart', 'domain/b.dart', allowed: true),
  ('$_occ/occupancy.dart', 'application/usecases/b.dart', allowed: true),
  ('$_occ/occupancy.dart', 'infrastructure/b.dart', allowed: false),
  ('$_occ/occupancy.dart', 'presentation/b.dart', allowed: false),

  // --- composition ---
  (
    'composition/lot_home/a.dart',
    '$_pkg/contexts/occupancy/occupancy.dart',
    allowed: true,
  ),
  (
    'composition/lot_home/a.dart',
    '../../contexts/occupancy/occupancy.dart',
    allowed: true,
  ),
  (
    'composition/lot_home/a.dart',
    '$_pkg/core/result/result.dart',
    allowed: true,
  ),
  ('composition/lot_home/a.dart', '../other/b.dart', allowed: true),
  ('composition/lot_home/a.dart', _flutterMaterial, allowed: true),
  (
    'composition/lot_home/a.dart',
    '$_pkg/contexts/occupancy/domain/b.dart',
    allowed: false,
  ),
  (
    'composition/lot_home/a.dart',
    '../../contexts/occupancy/presentation/b.dart',
    allowed: false,
  ),
  ('composition/lot_home/a.dart', '$_pkg/app/di/injector.dart', allowed: false),

  // --- core ---
  ('core/network/a.dart', 'package:dio/dio.dart', allowed: true),
  ('core/network/a.dart', '../result/b.dart', allowed: true),
  ('core/design_system/a.dart', _flutterMaterial, allowed: true),
  ('core/design_system/a.dart', 'dart:ui', allowed: true),
  // Excepción: el código generado de i18n usa Flutter; ninguna otra área.
  ('core/l10n/a.dart', _flutterMaterial, allowed: true),
  ('core/l10n/a.dart', '$_pkg/contexts/iam/iam.dart', allowed: false),
  ('core/network/a.dart', _flutterMaterial, allowed: false),
  ('core/view_state/a.dart', _flutterMaterial, allowed: false),
  (
    'contexts/iam/presentation/a.dart',
    '$_pkg/core/l10n/app_localizations.dart',
    allowed: true,
  ),
  (
    'composition/sign_out/a.dart',
    '$_pkg/core/l10n/app_localizations.dart',
    allowed: true,
  ),
  // Los plugins de almacenamiento no son el framework de Flutter.
  (
    'core/storage/a.dart',
    'package:flutter_secure_storage/flutter_secure_storage.dart',
    allowed: true,
  ),
  (
    'core/network/a.dart',
    'package:flutter_bloc/flutter_bloc.dart',
    allowed: false,
  ),
  ('core/time/a.dart', 'dart:ui', allowed: false),
  (
    'core/network/a.dart',
    '$_pkg/contexts/occupancy/occupancy.dart',
    allowed: false,
  ),
  // Extra: core no depende de app ni de composition.
  ('core/network/a.dart', '$_pkg/app/config/app_config.dart', allowed: false),
  ('core/network/a.dart', '$_pkg/composition/x/y.dart', allowed: false),

  // --- app (raíz de composición): puede importar todo ---
  (
    'app/di/injector.dart',
    '$_pkg/contexts/occupancy/infrastructure/b.dart',
    allowed: true,
  ),
  ('app/di/injector.dart', 'package:get_it/get_it.dart', allowed: true),
  ('bootstrap.dart', '$_pkg/app/app.dart', allowed: true),
];

void main() {
  group('reglas de dependencias (casos sintéticos)', () {
    for (final (from, uri, :allowed) in _cases) {
      test('lib/$from -> $uri: ${allowed ? 'permitido' : 'prohibido'}', () {
        final reason = checkImport(from, uri);
        if (allowed) {
          expect(reason, isNull);
        } else {
          expect(reason, isNotNull, reason: 'debería estar prohibido');
        }
      });
    }
  });

  group('estructura de carpetas', () {
    test('clasifica las ubicaciones previstas', () {
      expect(
        classify('contexts/occupancy/domain/a.dart'),
        isA<ContextLayerModule>(),
      );
      expect(
        classify('contexts/occupancy/occupancy.dart'),
        isA<ContextBarrelModule>(),
      );
      expect(classify('composition/x/a.dart'), isA<CompositionModule>());
      expect(classify('core/time/a.dart'), isA<CoreModule>());
      expect(classify('app/app.dart'), isA<AppModule>());
      expect(classify('main.dart'), isA<AppModule>());
      expect(classify('bootstrap.dart'), isA<AppModule>());
    });

    test('marca las ubicaciones no previstas', () {
      expect(
        classify('contexts/occupancy/utils/a.dart'),
        isA<ContextMisplacedModule>(),
      );
      expect(
        classify('contexts/occupancy/a.dart'),
        isA<ContextMisplacedModule>(),
      );
      expect(classify('shared/a.dart'), isA<UnknownModule>());
      expect(classify('otro.dart'), isA<UnknownModule>());
    });
  });

  group('escáner', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('quadrapp_arch_');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    void write(String path, String content) {
      File('${temp.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('detecta import, export y ubicaciones prohibidas', () {
      write(
        'contexts/occupancy/domain/a.dart',
        "import 'package:flutter/material.dart';\n",
      );
      write(
        'contexts/occupancy/presentation/p.dart',
        "import '../infrastructure/i.dart';\n",
      );
      write(
        'contexts/occupancy/occupancy.dart',
        "export 'infrastructure/i.dart';\n",
      );
      write('contexts/occupancy/infrastructure/i.dart', '// vacío\n');
      write('contexts/occupancy/utils/u.dart', '// fuera de capas\n');
      write(
        'composition/c.dart',
        "import 'package:quadrapp_mobile/app/x.dart';\n",
      );
      write('shared/s.dart', '// carpeta no prevista\n');

      final violations = scanLib(temp);

      expect(
        violations.map((v) => v.file),
        unorderedEquals([
          'composition/c.dart',
          'contexts/occupancy/domain/a.dart',
          'contexts/occupancy/occupancy.dart',
          'contexts/occupancy/presentation/p.dart',
          'contexts/occupancy/utils/u.dart',
          'shared/s.dart',
        ]),
      );
    });

    test('ignora imports dentro de comentarios y acepta código válido', () {
      write(
        'contexts/occupancy/domain/a.dart',
        "// import 'package:flutter/material.dart';\n"
            "/// import 'package:dio/dio.dart';\n"
            "import 'package:equatable/equatable.dart';\n",
      );

      expect(scanLib(temp), isEmpty);
    });
  });

  test('lib/ cumple las reglas de docs/04', () {
    final violations = scanLib(Directory('lib'));

    expect(
      violations,
      isEmpty,
      reason: 'Reglas de dependencia rotas:\n${violations.join('\n')}',
    );
  });
}
