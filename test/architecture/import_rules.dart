// Reglas de dependencias de docs/04 ("Reglas de dependencia").
//
// Funciones puras sobre rutas relativas a `lib/` (con `/`) y URIs de
// `import`/`export`, para poder probarlas sin archivos reales.
import 'dart:io';

const _layers = {'domain', 'application', 'infrastructure', 'presentation'};
const _domainCoreAreas = {'identifiers', 'result', 'error', 'time'};
const _domainPackages = {'equatable', 'meta', 'collection'};
const _appPackage = 'quadrapp_mobile';

/// Módulo al que pertenece un archivo de `lib/`.
sealed class Module {
  const Module();
}

/// `contexts/<context>/<layer>/...`
final class ContextLayerModule extends Module {
  const ContextLayerModule(this.context, this.layer);
  final String context;
  final String layer;
}

/// `contexts/<context>/<context>.dart` (API pública del contexto).
final class ContextBarrelModule extends Module {
  const ContextBarrelModule(this.context);
  final String context;
}

/// Archivo dentro de un contexto pero fuera de las cuatro capas.
final class ContextMisplacedModule extends Module {
  const ContextMisplacedModule(this.context);
  final String context;
}

/// `composition/...`
final class CompositionModule extends Module {
  const CompositionModule();
}

/// `core/<area>/...`
final class CoreModule extends Module {
  const CoreModule(this.area);
  final String area;
}

/// `app/...`, `main.dart` y `bootstrap.dart`.
final class AppModule extends Module {
  const AppModule();
}

/// Ubicación no prevista en docs/04.
final class UnknownModule extends Module {
  const UnknownModule();
}

/// Clasifica una ruta relativa a `lib/` (por ejemplo `core/time/clock.dart`).
Module classify(String path) {
  final parts = path.split('/');
  if (parts.length == 1) {
    return parts.first == 'main.dart' || parts.first == 'bootstrap.dart'
        ? const AppModule()
        : const UnknownModule();
  }
  switch (parts.first) {
    case 'app':
      return const AppModule();
    case 'composition':
      return const CompositionModule();
    case 'core':
      return CoreModule(parts.length > 2 ? parts[1] : '');
    case 'contexts':
      if (parts.length < 3) return const UnknownModule();
      final context = parts[1];
      if (parts.length == 3 && parts[2] == '$context.dart') {
        return ContextBarrelModule(context);
      }
      if (parts.length >= 4 && _layers.contains(parts[2])) {
        return ContextLayerModule(context, parts[2]);
      }
      return ContextMisplacedModule(context);
  }
  return const UnknownModule();
}

String _describe(Module module) => switch (module) {
  ContextLayerModule(:final context, :final layer) =>
    'la capa $layer del contexto $context',
  ContextBarrelModule(:final context) => 'el archivo público de $context',
  ContextMisplacedModule(:final context) =>
    'un archivo de $context fuera de sus capas',
  CompositionModule() => 'composition/',
  CoreModule(:final area) => area.isEmpty ? 'core/' : 'core/$area',
  AppModule() => 'app/',
  UnknownModule() => 'una carpeta no prevista',
};

sealed class _Target {
  const _Target();
}

final class _DartTarget extends _Target {
  const _DartTarget(this.library);
  final String library;
}

final class _PackageTarget extends _Target {
  const _PackageTarget(this.name);
  final String name;
}

final class _InternalTarget extends _Target {
  const _InternalTarget(this.path);
  final String path;
}

_Target _resolve(String from, String uri) {
  if (uri.startsWith('dart:')) return _DartTarget(uri.substring(5));
  if (uri.startsWith('package:')) {
    final withoutScheme = uri.substring(8);
    final slash = withoutScheme.indexOf('/');
    final name = withoutScheme.substring(0, slash);
    if (name == _appPackage) {
      return _InternalTarget(withoutScheme.substring(slash + 1));
    }
    return _PackageTarget(name);
  }
  return _InternalTarget(Uri.parse(from).resolve(uri).path);
}

bool _isFlutterPackage(String name) => name.startsWith('flutter');

/// El framework de Flutter y sus enlaces de estado (no los plugins).
bool _isFlutterFramework(String name) => const {
  'flutter',
  'flutter_localizations',
  'flutter_bloc',
  'flutter_test',
  'flutter_web_plugins',
}.contains(name);

/// Devuelve el motivo si `from` no puede importar `uri`; `null` si puede.
String? checkImport(String from, String uri) {
  final target = _resolve(from, uri);
  return switch (classify(from)) {
    ContextLayerModule(layer: 'domain', :final context) => _checkDomain(
      context,
      target,
    ),
    ContextLayerModule(layer: 'application', :final context) =>
      _checkApplication(context, target),
    ContextLayerModule(layer: 'infrastructure', :final context) =>
      _checkInfrastructure(context, target),
    ContextLayerModule(layer: 'presentation', :final context) =>
      _checkPresentation(context, target),
    ContextBarrelModule(:final context) => _checkBarrel(context, target),
    CompositionModule() => _checkComposition(target),
    CoreModule(:final area) => _checkCore(area, target),
    _ => null,
  };
}

String? _checkDomain(String context, _Target target) {
  switch (target) {
    case _DartTarget(:final library):
      return library == 'ui'
          ? 'domain es Dart puro: no puede usar dart:ui'
          : null;
    case _PackageTarget(:final name):
      return _domainPackages.contains(name)
          ? null
          : 'domain es Dart puro: no puede importar package:$name '
                '(permitidos: ${_domainPackages.join(', ')})';
    case _InternalTarget(:final path):
      final module = classify(path);
      final allowed = switch (module) {
        ContextLayerModule(context: final c, layer: 'domain') => c == context,
        CoreModule(:final area) => _domainCoreAreas.contains(area),
        _ => false,
      };
      return allowed
          ? null
          : 'domain solo puede importar su propio domain y '
                'core/{${_domainCoreAreas.join(',')}}, no ${_describe(module)}';
  }
}

String? _checkApplication(String context, _Target target) {
  switch (target) {
    case _DartTarget(:final library):
      return library == 'ui'
          ? 'application no puede usar Flutter (dart:ui)'
          : null;
    case _PackageTarget(:final name):
      if (_isFlutterPackage(name)) {
        return 'application no puede importar Flutter (package:$name)';
      }
      if (name == 'get_it') {
        return 'application recibe dependencias por constructor: '
            'get_it solo se usa en app/di';
      }
      return null;
    case _InternalTarget(:final path):
      final module = classify(path);
      final allowed = switch (module) {
        ContextLayerModule(context: final c, :final layer) =>
          c == context && (layer == 'domain' || layer == 'application'),
        CoreModule() => true,
        ContextBarrelModule(context: final c) => c != context,
        _ => false,
      };
      return allowed
          ? null
          : 'application solo puede importar su domain, core/* y el archivo '
                'público de otros contextos, no ${_describe(module)}';
  }
}

String? _checkInfrastructure(String context, _Target target) {
  if (target is! _InternalTarget) return null;
  final module = classify(target.path);
  final allowed = switch (module) {
    ContextLayerModule(context: final c, :final layer) =>
      c == context && (layer == 'domain' || layer == 'infrastructure'),
    CoreModule() => true,
    _ => false,
  };
  return allowed
      ? null
      : 'infrastructure solo puede importar su domain y core/*, '
            'no ${_describe(module)}';
}

String? _checkPresentation(String context, _Target target) {
  if (target is! _InternalTarget) return null;
  final module = classify(target.path);
  final allowed = switch (module) {
    ContextLayerModule(context: final c, :final layer) =>
      c == context && layer != 'infrastructure',
    CoreModule() => true,
    ContextBarrelModule(context: final c) => c != context,
    _ => false,
  };
  return allowed
      ? null
      : 'presentation solo puede importar su application, su domain, core/* '
            'y el archivo público de otros contextos, no ${_describe(module)}';
}

String? _checkBarrel(String context, _Target target) {
  if (target is! _InternalTarget) return null;
  final module = classify(target.path);
  final allowed = switch (module) {
    ContextLayerModule(context: final c, :final layer) =>
      c == context && (layer == 'domain' || layer == 'application'),
    _ => false,
  };
  return allowed
      ? null
      : 'el archivo público solo exporta domain y application de su contexto, '
            'no ${_describe(module)}';
}

String? _checkComposition(_Target target) {
  if (target is! _InternalTarget) return null;
  final module = classify(target.path);
  final allowed = switch (module) {
    CompositionModule() || CoreModule() || ContextBarrelModule() => true,
    _ => false,
  };
  return allowed
      ? null
      : 'composition solo puede importar el archivo público de los contextos '
            'y core/*, no ${_describe(module)}';
}

String? _checkCore(String area, _Target target) {
  // Única excepción además del design system: el código generado de i18n
  // (`core/l10n`) depende de Flutter (docs/04). No hay lógica ahí.
  final mayUseFlutter = area == 'design_system' || area == 'l10n';
  switch (target) {
    case _DartTarget(:final library):
      return library == 'ui' && !mayUseFlutter
          ? 'core solo puede usar Flutter en design_system y l10n '
                '(dart:ui)'
          : null;
    case _PackageTarget(:final name):
      return _isFlutterFramework(name) && !mayUseFlutter
          ? 'core solo puede usar Flutter en design_system y l10n '
                '(package:$name)'
          : null;
    case _InternalTarget(:final path):
      final module = classify(path);
      return module is CoreModule
          ? null
          : 'core no puede importar contextos, app ni composition, '
                'no ${_describe(module)}';
  }
}

/// Un import o export que rompe una regla.
class Violation {
  const Violation({
    required this.file,
    required this.reason,
    this.directive,
  });

  final String file;
  final String? directive;
  final String reason;

  @override
  String toString() =>
      'lib/$file${directive == null ? '' : " -> $directive"}: $reason';
}

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Recorre todos los `.dart` bajo [lib] y devuelve las violaciones.
List<Violation> scanLib(Directory lib) {
  final root = lib.path.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
  final violations = <Violation>[];
  final files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/').substring(root.length + 1);
    final module = classify(path);
    if (module is ContextMisplacedModule || module is UnknownModule) {
      violations.add(
        Violation(
          file: path,
          reason:
              'ubicación no prevista en docs/04 (${_describe(module)}); '
              'un contexto solo tiene domain, application, infrastructure, '
              'presentation y su archivo público',
        ),
      );
      continue;
    }
    for (final match in _directive.allMatches(file.readAsStringSync())) {
      final uri = match.group(1)!;
      final reason = checkImport(path, uri);
      if (reason != null) {
        violations.add(Violation(file: path, directive: uri, reason: reason));
      }
    }
  }
  return violations;
}
