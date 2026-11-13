// US17 (editar la distribución desde la app del administrador de universidad)
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/zone.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/space_type.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

// ------------------------------------------------------------------ cambios

/// Un espacio que el borrador crea.
class NewSpace extends Equatable {
  const NewSpace({
    required this.key,
    required this.label,
    this.type = SpaceType.standard,
    this.enabled = true,
  });

  final String key;
  final String label;
  final SpaceType type;

  /// Si cuenta en el aforo en cuanto se publique.
  final bool enabled;

  @override
  List<Object?> get props => [key, label, type, enabled];
}

/// Un cambio del borrador, en el orden en que se hizo (para deshacer).
sealed class LayoutChange extends Equatable {
  const LayoutChange();
}

/// Una zona nueva con un nivel y sus espacios iniciales.
final class AddZone extends LayoutChange {
  const AddZone({
    required this.key,
    required this.name,
    required this.levelName,
    required this.spaces,
  });

  final String key;
  final String name;
  final String levelName;
  final List<NewSpace> spaces;

  /// La clave del único nivel de la zona nueva.
  String get levelKey => 'l$key';

  @override
  List<Object?> get props => [key, name, levelName, spaces];
}

/// Un espacio nuevo en un nivel (publicado o del borrador).
final class AddSpace extends LayoutChange {
  const AddSpace({
    required this.zoneKey,
    required this.levelKey,
    required this.space,
  });

  final String zoneKey;
  final String levelKey;
  final NewSpace space;

  @override
  List<Object?> get props => [zoneKey, levelKey, space];
}

/// Cambia el código o el tipo de un espacio.
final class EditSpace extends LayoutChange {
  const EditSpace({
    required this.spaceKey,
    required this.label,
    required this.type,
  });

  final String spaceKey;
  final String label;
  final SpaceType type;

  @override
  List<Object?> get props => [spaceKey, label, type];
}

/// Deshabilita (deja de contar en el aforo) o vuelve a habilitar un espacio.
final class SetSpaceEnabled extends LayoutChange {
  const SetSpaceEnabled({required this.spaceKey, required this.enabled});

  final String spaceKey;
  final bool enabled;

  @override
  List<Object?> get props => [spaceKey, enabled];
}

// ------------------------------------------------- distribución con cambios

/// Un espacio tal como quedará al publicar.
class DraftSpace extends Equatable {
  const DraftSpace({
    required this.key,
    required this.label,
    required this.type,
    required this.enabled,
    required this.isNew,
    this.isEdited = false,
    this.id,
  });

  final String key;

  /// `null` si es nuevo.
  final SpaceId? id;
  final String label;
  final SpaceType type;
  final bool enabled;
  final bool isNew;
  final bool isEdited;

  DraftSpace copyWith({String? label, SpaceType? type, bool? enabled}) =>
      DraftSpace(
        key: key,
        id: id,
        label: label ?? this.label,
        type: type ?? this.type,
        enabled: enabled ?? this.enabled,
        isNew: isNew,
        isEdited: isEdited || label != null || type != null,
      );

  @override
  List<Object?> get props => [key, id?.value, label, type, enabled, isNew];
}

/// Un nivel tal como quedará al publicar.
class DraftLevel extends Equatable {
  const DraftLevel({
    required this.key,
    required this.name,
    required this.spaces,
    this.id,
  });

  final String key;
  final LevelId? id;
  final String name;
  final List<DraftSpace> spaces;

  @override
  List<Object?> get props => [key, id?.value, name, spaces];
}

/// Una zona tal como quedará al publicar.
class DraftZone extends Equatable {
  const DraftZone({
    required this.key,
    required this.name,
    required this.levels,
    this.id,
  });

  final String key;

  /// `null` si es nueva.
  final ZoneId? id;
  final String name;
  final List<DraftLevel> levels;

  bool get isNew => id == null;

  List<DraftSpace> get spaces => [for (final l in levels) ...l.spaces];

  /// Los que cuentan en el aforo.
  int get enabledCount => spaces.where((s) => s.enabled).length;

  @override
  List<Object?> get props => [key, id?.value, name, levels];
}

/// La distribución publicada con los cambios del borrador aplicados.
class DraftLayout extends Equatable {
  const DraftLayout(this.zones);

  final List<DraftZone> zones;

  List<DraftSpace> get spaces => [for (final z in zones) ...z.spaces];

  int get enabledCount => spaces.where((s) => s.enabled).length;

  DraftZone? zone(String key) => zones.where((z) => z.key == key).firstOrNull;

  DraftSpace? space(String key) =>
      spaces.where((s) => s.key == key).firstOrNull;

  /// La zona de un espacio.
  DraftZone? zoneOf(String spaceKey) =>
      zones.where((z) => z.spaces.any((s) => s.key == spaceKey)).firstOrNull;

  /// ¿Otro espacio del estacionamiento ya usa [label]? (sin distinguir
  /// mayúsculas; [exceptKey] es el espacio que se edita).
  bool labelTaken(String label, {String? exceptKey}) {
    final needle = label.trim().toLowerCase();
    return spaces.any(
      (s) => s.key != exceptKey && s.label.toLowerCase() == needle,
    );
  }

  bool zoneNameTaken(String name) {
    final needle = name.trim().toLowerCase();
    return zones.any((z) => z.name.toLowerCase() == needle);
  }

  @override
  List<Object?> get props => [zones];
}

// ------------------------------------------------------ errores y resultados

/// Por qué el borrador rechaza un cambio.
enum DraftError {
  zoneNameRequired,
  zoneNameTooLong,
  zoneNameTaken,
  levelNameTooLong,
  spacesOutOfRange,
  zoneRequired,
  levelRequired,
  labelRequired,
  labelTooLong,
  labelTaken,
  spaceNotFound,
}

/// El resultado de intentar un cambio: el borrador nuevo o el motivo.
sealed class DraftEdit {
  const DraftEdit();
}

final class DraftApplied extends DraftEdit {
  const DraftApplied(this.draft);

  final LayoutDraft draft;
}

final class DraftRejected extends DraftEdit {
  const DraftRejected(this.error);

  final DraftError error;
}

/// Lo que dice la ventana «¿Publicar?»: antes y después.
class PublishSummary extends Equatable {
  const PublishSummary({
    required this.zonesBefore,
    required this.zonesAfter,
    required this.spacesBefore,
    required this.spacesAfter,
    required this.disabledLabels,
    required this.newSpaces,
    required this.editedSpaces,
  });

  final int zonesBefore;
  final int zonesAfter;

  /// Espacios que cuentan en el aforo.
  final int spacesBefore;
  final int spacesAfter;

  /// Los espacios publicados que dejarán de contar.
  final List<String> disabledLabels;
  final int newSpaces;
  final int editedSpaces;

  @override
  List<Object?> get props => [
    zonesBefore,
    zonesAfter,
    spacesBefore,
    spacesAfter,
    disabledLabels,
    newSpaces,
    editedSpaces,
  ];
}

/// Una zona que se crea al publicar.
class PlannedZone extends Equatable {
  const PlannedZone({
    required this.key,
    required this.name,
    required this.levelName,
  });

  final String key;
  final String name;
  final String levelName;

  @override
  List<Object?> get props => [key, name, levelName];
}

/// Un espacio que se crea al publicar: en un nivel publicado ([levelId]) o en
/// el nivel de una zona nueva ([zoneKey]).
class PlannedSpace extends Equatable {
  const PlannedSpace({
    required this.label,
    required this.type,
    required this.enabled,
    this.levelId,
    this.zoneKey,
  });

  final LevelId? levelId;
  final String? zoneKey;
  final String label;
  final SpaceType type;
  final bool enabled;

  @override
  List<Object?> get props => [levelId?.value, zoneKey, label, type, enabled];
}

/// Un espacio publicado al que le cambia el código o el tipo.
class PlannedEdit extends Equatable {
  const PlannedEdit({
    required this.spaceId,
    required this.label,
    required this.type,
  });

  final SpaceId spaceId;
  final String label;
  final SpaceType type;

  @override
  List<Object?> get props => [spaceId.value, label, type];
}

/// Lo que se envía al publicar: el efecto neto del borrador sobre la versión
/// publicada (no la lista de pasos).
class PublishPlan extends Equatable {
  const PublishPlan({
    required this.lotId,
    required this.baseVersion,
    required this.newZones,
    required this.newSpaces,
    required this.editedSpaces,
    required this.disabledSpaceIds,
  });

  final LotId lotId;
  final int baseVersion;
  final List<PlannedZone> newZones;
  final List<PlannedSpace> newSpaces;
  final List<PlannedEdit> editedSpaces;
  final List<SpaceId> disabledSpaceIds;

  bool get isEmpty =>
      newZones.isEmpty &&
      newSpaces.isEmpty &&
      editedSpaces.isEmpty &&
      disabledSpaceIds.isEmpty;

  @override
  List<Object?> get props => [
    lotId.value,
    baseVersion,
    newZones,
    newSpaces,
    editedSpaces,
    disabledSpaceIds.map((id) => id.value).toList(),
  ];
}

// ------------------------------------------------------------------ borrador

/// El borrador de la distribución de un estacionamiento (US17): los cambios
/// que el administrador de universidad prepara sobre la versión publicada
/// ([baseVersion]) y que nadie más ve hasta publicar. Vive en el teléfono.
///
/// Reglas: el nombre de una zona y el código de un espacio son únicos en el
/// estacionamiento (sin distinguir mayúsculas); una zona nueva nace con un
/// nivel y de 1 a [maxInitialSpaces] espacios; deshabilitar un espacio lo saca
/// del aforo al publicar y se puede revertir antes.
class LayoutDraft extends Equatable {
  const LayoutDraft({
    required this.lotId,
    required this.baseVersion,
    this.changes = const [],
    this.nextSeq = 1,
  });

  static const int maxZoneName = 60;
  static const int maxLevelName = 40;
  static const int maxLabel = 20;
  static const int maxInitialSpaces = 200;

  final LotId lotId;

  /// La versión publicada sobre la que se hicieron los cambios (0 = sin
  /// distribución publicada).
  final int baseVersion;
  final List<LayoutChange> changes;

  /// Para las claves de lo que se crea.
  final int nextSeq;

  bool get isEmpty => changes.isEmpty;

  /// La versión que se publicará.
  int get targetVersion => baseVersion + 1;

  static String zoneKeyOf(ZoneId id) => 'z${id.value}';
  static String levelKeyOf(LevelId id) => 'l${id.value}';
  static String spaceKeyOf(SpaceId id) => 's${id.value}';

  LayoutDraft _with(LayoutChange change, {int used = 0}) => LayoutDraft(
    lotId: lotId,
    baseVersion: baseVersion,
    changes: [...changes, change],
    nextSeq: nextSeq + used,
  );

  /// Quita el último cambio.
  LayoutDraft undo() => changes.isEmpty
      ? this
      : LayoutDraft(
          lotId: lotId,
          baseVersion: baseVersion,
          changes: changes.sublist(0, changes.length - 1),
          nextSeq: nextSeq,
        );

  // ------------------------------------------------------------- aplicar

  /// [base] con los cambios aplicados (sin distribución publicada, `null`).
  DraftLayout applyTo(LotLayout? base) {
    final zones = <_Zone>[
      for (final zone in base?.zones ?? const <Zone>[])
        _Zone(zoneKeyOf(zone.id), zone.id, zone.name, [
          for (final level in zone.levels)
            _Level(levelKeyOf(level.id), level.id, level.name, [
              for (final space in level.spaces)
                DraftSpace(
                  key: spaceKeyOf(space.id),
                  id: space.id,
                  label: space.label,
                  type: space.type,
                  enabled: true,
                  isNew: false,
                ),
            ]),
        ]),
    ];

    DraftSpace? replace(String key, DraftSpace Function(DraftSpace) update) {
      for (final zone in zones) {
        for (final level in zone.levels) {
          final i = level.spaces.indexWhere((s) => s.key == key);
          if (i >= 0) return level.spaces[i] = update(level.spaces[i]);
        }
      }
      return null;
    }

    DraftSpace fromNew(NewSpace s) => DraftSpace(
      key: s.key,
      label: s.label,
      type: s.type,
      enabled: s.enabled,
      isNew: true,
    );

    for (final change in changes) {
      switch (change) {
        case AddZone():
          zones.add(
            _Zone(change.key, null, change.name, [
              _Level(change.levelKey, null, change.levelName, [
                for (final s in change.spaces) fromNew(s),
              ]),
            ]),
          );
        case AddSpace():
          final zone = zones.where((z) => z.key == change.zoneKey).firstOrNull;
          final level = zone?.levels
              .where((l) => l.key == change.levelKey)
              .firstOrNull;
          level?.spaces.add(fromNew(change.space));
        case EditSpace():
          replace(
            change.spaceKey,
            (s) => s.copyWith(label: change.label, type: change.type),
          );
        case SetSpaceEnabled():
          replace(change.spaceKey, (s) => s.copyWith(enabled: change.enabled));
      }
    }

    return DraftLayout([
      for (final zone in zones)
        DraftZone(
          key: zone.key,
          id: zone.id,
          name: zone.name,
          levels: [
            for (final level in zone.levels)
              DraftLevel(
                key: level.key,
                id: level.id,
                name: level.name,
                spaces: List.unmodifiable(level.spaces),
              ),
          ],
        ),
    ]);
  }

  // -------------------------------------------------------------- editar

  /// Agrega una zona con un nivel ([levelName]) y [initialSpaces] espacios
  /// con códigos generados a partir del nombre («Zona Este» → E-01, E-02...).
  DraftEdit addZone(
    LotLayout? base, {
    required String name,
    required String levelName,
    required int initialSpaces,
  }) {
    final clean = name.trim();
    final level = levelName.trim();
    if (clean.isEmpty) return const DraftRejected(DraftError.zoneNameRequired);
    if (clean.length > maxZoneName) {
      return const DraftRejected(DraftError.zoneNameTooLong);
    }
    if (level.length > maxLevelName) {
      return const DraftRejected(DraftError.levelNameTooLong);
    }
    if (initialSpaces < 1 || initialSpaces > maxInitialSpaces) {
      return const DraftRejected(DraftError.spacesOutOfRange);
    }
    final current = applyTo(base);
    if (current.zoneNameTaken(clean)) {
      return const DraftRejected(DraftError.zoneNameTaken);
    }
    final prefix = _freePrefix(current, clean);
    final width = '$initialSpaces'.length < 2 ? 2 : '$initialSpaces'.length;
    final seq = nextSeq;
    final spaces = <NewSpace>[];
    var number = 1;
    for (var i = 0; i < initialSpaces; i++) {
      String label;
      do {
        label = '$prefix-${'$number'.padLeft(width, '0')}';
        number++;
      } while (current.labelTaken(label));
      spaces.add(NewSpace(key: 'ns$seq-$i', label: label));
    }
    return DraftApplied(
      _with(
        AddZone(key: 'nz$seq', name: clean, levelName: level, spaces: spaces),
        used: 1,
      ),
    );
  }

  /// Agrega un espacio a [zoneKey]. Si la zona tiene un solo nivel, va a ese
  /// nivel; si tiene varios, [levelKey] es obligatorio.
  DraftEdit addSpace(
    LotLayout? base, {
    required String? zoneKey,
    required String label,
    String? levelKey,
    SpaceType type = SpaceType.standard,
    bool enabled = true,
  }) {
    final current = applyTo(base);
    final zone = zoneKey == null ? null : current.zone(zoneKey);
    if (zone == null) return const DraftRejected(DraftError.zoneRequired);
    final level = zone.levels.length == 1
        ? zone.levels.single
        : zone.levels.where((l) => l.key == levelKey).firstOrNull;
    if (level == null) return const DraftRejected(DraftError.levelRequired);
    final error = _labelError(current, label);
    if (error != null) return DraftRejected(error);
    return DraftApplied(
      _with(
        AddSpace(
          zoneKey: zone.key,
          levelKey: level.key,
          space: NewSpace(
            key: 'ns$nextSeq',
            label: label.trim(),
            type: type,
            enabled: enabled,
          ),
        ),
        used: 1,
      ),
    );
  }

  /// Cambia el código o el tipo de un espacio.
  DraftEdit editSpace(
    LotLayout? base, {
    required String spaceKey,
    required String label,
    required SpaceType type,
  }) {
    final current = applyTo(base);
    final space = current.space(spaceKey);
    if (space == null) return const DraftRejected(DraftError.spaceNotFound);
    final error = _labelError(current, label, exceptKey: spaceKey);
    if (error != null) return DraftRejected(error);
    if (space.label == label.trim() && space.type == type) {
      return DraftApplied(this);
    }
    return DraftApplied(
      _with(EditSpace(spaceKey: spaceKey, label: label.trim(), type: type)),
    );
  }

  /// Deshabilita o vuelve a habilitar un espacio. Uno que ya está en ese
  /// estado no agrega un cambio.
  LayoutDraft setEnabled(
    LotLayout? base, {
    required String spaceKey,
    required bool enabled,
  }) {
    final space = applyTo(base).space(spaceKey);
    if (space == null || space.enabled == enabled) return this;
    return _with(SetSpaceEnabled(spaceKey: spaceKey, enabled: enabled));
  }

  DraftError? _labelError(
    DraftLayout current,
    String label, {
    String? exceptKey,
  }) {
    final clean = label.trim();
    if (clean.isEmpty) return DraftError.labelRequired;
    if (clean.length > maxLabel) return DraftError.labelTooLong;
    if (current.labelTaken(clean, exceptKey: exceptKey)) {
      return DraftError.labelTaken;
    }
    return null;
  }

  // ------------------------------------------------------------ sugerir

  /// El siguiente código libre para [zoneKey]: sigue el patrón de sus
  /// espacios («C-140» → «C-141») o, si no tiene, el del nombre de la zona.
  String suggestLabel(LotLayout? base, String zoneKey) {
    final current = applyTo(base);
    final zone = current.zone(zoneKey);
    if (zone == null) return '';
    final pattern = RegExp(r'^([A-Za-z]+)-(\d+)$');
    final byPrefix = <String, List<RegExpMatch>>{};
    for (final space in zone.spaces) {
      final match = pattern.firstMatch(space.label);
      if (match != null) {
        byPrefix.putIfAbsent(match.group(1)!, () => []).add(match);
      }
    }
    String prefix;
    var next = 1;
    var width = 2;
    if (byPrefix.isEmpty) {
      prefix = _freePrefix(current, zone.name);
    } else {
      final best = byPrefix.entries.reduce(
        (a, b) => b.value.length > a.value.length ? b : a,
      );
      prefix = best.key;
      for (final match in best.value) {
        final digits = match.group(2)!;
        final value = int.parse(digits);
        if (value >= next) next = value + 1;
        if (digits.length > width) width = digits.length;
      }
    }
    String label;
    do {
      label = '$prefix-${'$next'.padLeft(width, '0')}';
      next++;
    } while (current.labelTaken(label));
    return label;
  }

  /// Un prefijo de código para una zona nueva que ningún espacio usa: la
  /// inicial de la última palabra del nombre y, si está tomada, más letras.
  static String _freePrefix(DraftLayout current, String zoneName) {
    final words = zoneName
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp('[^A-Za-zÁÉÍÓÚÑáéíóúñ]'), ''))
        .where((w) => w.isNotEmpty)
        .toList();
    final word = words.isEmpty ? 'Z' : words.last;
    final ascii = word
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N');
    bool used(String prefix) => current.spaces.any(
      (s) => s.label.toUpperCase().startsWith('$prefix-'),
    );
    for (var n = 1; n <= ascii.length; n++) {
      final prefix = ascii.substring(0, n);
      if (!used(prefix)) return prefix;
    }
    var n = current.zones.length + 1;
    while (used('Z$n')) {
      n++;
    }
    return 'Z$n';
  }

  // ------------------------------------------------------------ publicar

  /// Antes y después, para la ventana de publicar.
  PublishSummary summary(LotLayout? base) {
    final after = applyTo(base);
    final edited = after.spaces.where((s) => !s.isNew && s.isEdited);
    return PublishSummary(
      zonesBefore: base?.zones.length ?? 0,
      zonesAfter: after.zones.length,
      spacesBefore: base?.spaceCount ?? 0,
      spacesAfter: after.enabledCount,
      disabledLabels: [
        for (final s in after.spaces)
          if (!s.isNew && !s.enabled) s.label,
      ],
      newSpaces: after.spaces.where((s) => s.isNew && s.enabled).length,
      editedSpaces: edited.length,
    );
  }

  /// El efecto neto del borrador sobre [base].
  PublishPlan plan(LotLayout? base) {
    final after = applyTo(base);
    final published = {
      for (final zone in base?.zones ?? const <Zone>[])
        for (final space in zone.spaces) space.id.value: space,
    };
    final newSpaces = <PlannedSpace>[];
    final edits = <PlannedEdit>[];
    final disabled = <SpaceId>[];
    for (final zone in after.zones) {
      for (final level in zone.levels) {
        for (final space in level.spaces) {
          if (space.isNew) {
            newSpaces.add(
              PlannedSpace(
                levelId: zone.isNew ? null : level.id,
                zoneKey: zone.isNew ? zone.key : null,
                label: space.label,
                type: space.type,
                enabled: space.enabled,
              ),
            );
            continue;
          }
          final before = published[space.id!.value];
          if (!space.enabled) disabled.add(space.id!);
          if (before != null &&
              (before.label != space.label || before.type != space.type)) {
            edits.add(
              PlannedEdit(
                spaceId: space.id!,
                label: space.label,
                type: space.type,
              ),
            );
          }
        }
      }
    }
    return PublishPlan(
      lotId: lotId,
      baseVersion: baseVersion,
      newZones: [
        for (final zone in after.zones)
          if (zone.isNew)
            PlannedZone(
              key: zone.key,
              name: zone.name,
              levelName: zone.levels.single.name,
            ),
      ],
      newSpaces: newSpaces,
      editedSpaces: edits,
      disabledSpaceIds: disabled,
    );
  }

  @override
  List<Object?> get props => [lotId.value, baseVersion, changes, nextSeq];
}

class _Zone {
  _Zone(this.key, this.id, this.name, this.levels);

  final String key;
  final ZoneId? id;
  final String name;
  final List<_Level> levels;
}

class _Level {
  _Level(this.key, this.id, this.name, this.spaces);

  final String key;
  final LevelId? id;
  final String name;
  final List<DraftSpace> spaces;
}
