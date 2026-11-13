import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/layout_draft.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/space_type.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/layout_draft_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/publish_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// El tipo de espacio con el valor de docs/07; uno desconocido es
/// `STANDARD` (lo más común) y deja un aviso sin datos personales.
SpaceType spaceTypeFromApi(String? raw, [Logger? logger]) {
  switch (raw) {
    case null:
    case 'STANDARD':
      return SpaceType.standard;
    case 'ACCESSIBLE':
      return SpaceType.accessible;
    default:
      logger?.warning('Tipo de espacio no reconocido "$raw": STANDARD');
      return SpaceType.standard;
  }
}

String spaceTypeToApi(SpaceType type) => switch (type) {
  SpaceType.standard => 'STANDARD',
  SpaceType.accessible => 'ACCESSIBLE',
};

/// Borrador <-> lo guardado en el teléfono, y el plan de publicación -> la
/// petición de docs/07.
class LayoutDraftMapper {
  const LayoutDraftMapper([this._logger]);

  final Logger? _logger;

  // ------------------------------------------------------------ guardado

  LayoutDraftDto toDto(LayoutDraft draft) => LayoutDraftDto(
    lotId: draft.lotId.value,
    baseVersion: draft.baseVersion,
    nextSeq: draft.nextSeq,
    changes: [for (final change in draft.changes) _changeToDto(change)],
  );

  /// Un cambio que no se reconoce se descarta (el borrador sigue usable).
  LayoutDraft fromDto(LayoutDraftDto dto) => LayoutDraft(
    lotId: LotId(dto.lotId),
    baseVersion: dto.baseVersion,
    nextSeq: dto.nextSeq,
    changes: [
      for (final change in dto.changes) ?_changeFromDto(change),
    ],
  );

  NewSpaceDto _spaceToDto(NewSpace s) => NewSpaceDto(
    key: s.key,
    label: s.label,
    type: spaceTypeToApi(s.type),
    enabled: s.enabled,
  );

  NewSpace _spaceFromDto(NewSpaceDto s) => NewSpace(
    key: s.key,
    label: s.label,
    type: spaceTypeFromApi(s.type, _logger),
    enabled: s.enabled,
  );

  LayoutChangeDto _changeToDto(LayoutChange change) => switch (change) {
    AddZone() => LayoutChangeDto(
      kind: 'ADD_ZONE',
      key: change.key,
      name: change.name,
      levelName: change.levelName,
      spaces: [for (final s in change.spaces) _spaceToDto(s)],
    ),
    AddSpace() => LayoutChangeDto(
      kind: 'ADD_SPACE',
      zoneKey: change.zoneKey,
      levelKey: change.levelKey,
      space: _spaceToDto(change.space),
    ),
    EditSpace() => LayoutChangeDto(
      kind: 'EDIT_SPACE',
      spaceKey: change.spaceKey,
      label: change.label,
      type: spaceTypeToApi(change.type),
    ),
    SetSpaceEnabled() => LayoutChangeDto(
      kind: 'SET_ENABLED',
      spaceKey: change.spaceKey,
      enabled: change.enabled,
    ),
  };

  LayoutChange? _changeFromDto(LayoutChangeDto dto) {
    switch (dto.kind) {
      case 'ADD_ZONE':
        return AddZone(
          key: dto.key!,
          name: dto.name!,
          levelName: dto.levelName ?? '',
          spaces: [
            for (final s in dto.spaces ?? const <NewSpaceDto>[])
              _spaceFromDto(s),
          ],
        );
      case 'ADD_SPACE':
        return AddSpace(
          zoneKey: dto.zoneKey!,
          levelKey: dto.levelKey!,
          space: _spaceFromDto(dto.space!),
        );
      case 'EDIT_SPACE':
        return EditSpace(
          spaceKey: dto.spaceKey!,
          label: dto.label!,
          type: spaceTypeFromApi(dto.type, _logger),
        );
      case 'SET_ENABLED':
        return SetSpaceEnabled(
          spaceKey: dto.spaceKey!,
          enabled: dto.enabled!,
        );
      default:
        _logger?.warning('Cambio de borrador no reconocido "${dto.kind}"');
        return null;
    }
  }

  // ------------------------------------------------------------ publicar

  PublishLayoutRequestDto toRequest(PublishPlan plan) =>
      PublishLayoutRequestDto(
        baseVersion: plan.baseVersion,
        newZones: [
          for (final zone in plan.newZones)
            NewZoneDto(
              key: zone.key,
              name: zone.name,
              levelName: zone.levelName,
            ),
        ],
        newSpaces: [
          for (final space in plan.newSpaces)
            PublishSpaceDto(
              levelId: space.levelId?.value,
              zoneKey: space.zoneKey,
              label: space.label,
              type: spaceTypeToApi(space.type),
              active: space.enabled,
            ),
        ],
        updatedSpaces: [
          for (final edit in plan.editedSpaces)
            UpdatedSpaceDto(
              spaceId: edit.spaceId.value,
              label: edit.label,
              type: spaceTypeToApi(edit.type),
            ),
        ],
        disabledSpaceIds: [for (final id in plan.disabledSpaceIds) id.value],
      );
}
