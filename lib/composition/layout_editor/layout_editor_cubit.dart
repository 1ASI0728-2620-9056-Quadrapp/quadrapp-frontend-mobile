// US17 (editar la distribución, administrador de universidad)
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Lo que ve el editor: la versión publicada ([base], `null` si aún no hay),
/// el borrador y lo elegido en el plano.
class LayoutEditorState extends Equatable {
  const LayoutEditorState({
    required this.lot,
    required this.base,
    required this.draft,
    this.selectedZoneKey,
    this.selectedSpaceKey,
    this.publishing = false,
  });

  final ParkingLot lot;
  final LotLayout? base;
  final LayoutDraft draft;
  final String? selectedZoneKey;
  final String? selectedSpaceKey;
  final bool publishing;

  /// La distribución con los cambios del borrador.
  DraftLayout get layout => draft.applyTo(base);

  DraftZone? get selectedZone =>
      selectedZoneKey == null ? null : layout.zone(selectedZoneKey!);

  DraftSpace? get selectedSpace =>
      selectedSpaceKey == null ? null : layout.space(selectedSpaceKey!);

  LayoutEditorState copyWith({
    LayoutDraft? draft,
    String? selectedZoneKey,
    String? selectedSpaceKey,
    bool clearSpace = false,
    bool? publishing,
  }) => LayoutEditorState(
    lot: lot,
    base: base,
    draft: draft ?? this.draft,
    selectedZoneKey: selectedZoneKey ?? this.selectedZoneKey,
    selectedSpaceKey: clearSpace
        ? null
        : selectedSpaceKey ?? this.selectedSpaceKey,
    publishing: publishing ?? this.publishing,
  );

  @override
  List<Object?> get props => [
    lot,
    base,
    draft,
    selectedZoneKey,
    selectedSpaceKey,
    publishing,
  ];
}

/// Avisos breves del editor para la pantalla.
sealed class LayoutEditorNotice {
  const LayoutEditorNotice();
}

/// Se publicó [version]: Estacionamientos debe recargarse.
final class LayoutPublished extends LayoutEditorNotice {
  const LayoutPublished(this.version);

  final int version;
}

/// La publicación falló por [failure].
final class LayoutPublishFailed extends LayoutEditorNotice {
  const LayoutPublishFailed(this.failure);

  final Failure failure;
}

/// El borrador guardado era de otra versión y se descartó.
final class LayoutDraftDiscarded extends LayoutEditorNotice {
  const LayoutDraftDiscarded();
}

/// El cambio se aplicó pero no se pudo guardar en el teléfono.
final class LayoutDraftNotSaved extends LayoutEditorNotice {
  const LayoutDraftNotSaved();
}

/// Cubit de «Editar distribución» (`/ops/zones/layout`, solo `ADMIN`).
///
/// Estados (`ViewState<LayoutEditorState>`): `ViewLoading` (skeleton),
/// `ViewError` (no se pudo leer la distribución) y `ViewData`. Las reglas del
/// borrador viven en el dominio ([LayoutDraft]); aquí solo se aplican, se
/// guarda el borrador en el teléfono tras cada cambio y se publica.
class LayoutEditorCubit extends Cubit<ViewState<LayoutEditorState>> {
  LayoutEditorCubit({
    required this._getLotLayout,
    required this._getDraft,
    required this._saveDraft,
    required this._discardDraft,
    required this._publishLayout,
  }) : super(const ViewInitial());

  final GetLotLayout _getLotLayout;
  final GetLayoutDraft _getDraft;
  final SaveLayoutDraft _saveDraft;
  final DiscardLayoutDraft _discardDraft;
  final PublishLayout _publishLayout;

  final StreamController<LayoutEditorNotice> _notices =
      StreamController<LayoutEditorNotice>.broadcast();

  Stream<LayoutEditorNotice> get notices => _notices.stream;

  ParkingLot? _lot;

  LayoutEditorState? get current => switch (state) {
    ViewData(:final data) => data,
    _ => null,
  };

  /// Lee la versión publicada de [lot] y su borrador. Un borrador hecho sobre
  /// otra versión ya no vale: se descarta y se avisa.
  Future<void> load(ParkingLot lot) async {
    _lot = lot;
    emit(const ViewLoading());
    LotLayout? base;
    if (lot.hasPublishedLayout) {
      final read = await _getLotLayout(lot.id);
      if (isClosed || _lot != lot) return;
      switch (read) {
        case Success(:final value):
          base = value;
        case Err(failure: NotFoundFailure()):
          base = null;
        case Err(:final failure):
          emit(ViewError(failure));
          return;
      }
    }
    final version = base?.version ?? 0;
    var draft = (await _getDraft(lot.id)).valueOrNull;
    if (isClosed || _lot != lot) return;
    if (draft != null && draft.baseVersion != version) {
      await _discardDraft(lot.id);
      _notices.add(const LayoutDraftDiscarded());
      draft = null;
    }
    draft ??= LayoutDraft(lotId: lot.id, baseVersion: version);
    final layout = draft.applyTo(base);
    emit(
      ViewData(
        LayoutEditorState(
          lot: lot,
          base: base,
          draft: draft,
          selectedZoneKey: layout.zones.firstOrNull?.key,
        ),
      ),
    );
  }

  Future<void> reload() async {
    final lot = _lot;
    if (lot != null) await load(lot);
  }

  void selectZone(String key) {
    final now = current;
    if (now == null) return;
    emit(ViewData(now.copyWith(selectedZoneKey: key, clearSpace: true)));
  }

  void selectSpace(String key) {
    final now = current;
    if (now == null) return;
    final zone = now.layout.zoneOf(key);
    emit(
      ViewData(
        now.copyWith(selectedZoneKey: zone?.key, selectedSpaceKey: key),
      ),
    );
  }

  /// Aplica [edit]; si se rechaza, devuelve el motivo y nada cambia.
  Future<DraftError?> _apply(
    DraftEdit Function(LayoutEditorState state) edit, {
    String? Function(LayoutDraft draft, LayoutEditorState state)? select,
    bool selectSpace = false,
  }) async {
    final now = current;
    if (now == null) return null;
    switch (edit(now)) {
      case DraftRejected(:final error):
        return error;
      case DraftApplied(:final draft):
        final key = select?.call(draft, now);
        var next = now.copyWith(draft: draft);
        if (key != null) {
          next = selectSpace
              ? next.copyWith(
                  selectedSpaceKey: key,
                  selectedZoneKey: next.layout.zoneOf(key)?.key,
                )
              : next.copyWith(selectedZoneKey: key, clearSpace: true);
        }
        emit(ViewData(next));
        await _save(draft);
        return null;
    }
  }

  Future<void> _save(LayoutDraft draft) async {
    final saved = await _saveDraft(draft);
    if (saved is Err<void>) _notices.add(const LayoutDraftNotSaved());
  }

  Future<DraftError?> addZone({
    required String name,
    required String levelName,
    required int initialSpaces,
  }) => _apply(
    (s) => s.draft.addZone(
      s.base,
      name: name,
      levelName: levelName,
      initialSpaces: initialSpaces,
    ),
    select: (draft, s) => draft.applyTo(s.base).zones.last.key,
  );

  Future<DraftError?> addSpace({
    required String? zoneKey,
    required String label,
    required SpaceType type,
    required bool enabled,
    String? levelKey,
  }) => _apply(
    (s) => s.draft.addSpace(
      s.base,
      zoneKey: zoneKey,
      levelKey: levelKey,
      label: label,
      type: type,
      enabled: enabled,
    ),
    select: (draft, _) => _lastNewSpaceKey(draft),
    selectSpace: true,
  );

  static String? _lastNewSpaceKey(LayoutDraft draft) {
    final last = draft.changes.lastOrNull;
    return last is AddSpace ? last.space.key : null;
  }

  Future<DraftError?> editSpace({
    required String spaceKey,
    required String label,
    required SpaceType type,
  }) => _apply(
    (s) => s.draft.editSpace(
      s.base,
      spaceKey: spaceKey,
      label: label,
      type: type,
    ),
  );

  Future<void> setEnabled(String spaceKey, {required bool enabled}) async {
    final now = current;
    if (now == null) return;
    final draft = now.draft.setEnabled(
      now.base,
      spaceKey: spaceKey,
      enabled: enabled,
    );
    if (identical(draft, now.draft)) return;
    emit(ViewData(now.copyWith(draft: draft)));
    await _save(draft);
  }

  /// Quita el último cambio. Lo elegido que ya no existe se deselecciona.
  Future<void> undo() async {
    final now = current;
    if (now == null || now.draft.isEmpty) return;
    final draft = now.draft.undo();
    final layout = draft.applyTo(now.base);
    final zoneKey = layout.zone(now.selectedZoneKey ?? '') != null
        ? now.selectedZoneKey
        : layout.zones.firstOrNull?.key;
    final spaceKey = layout.space(now.selectedSpaceKey ?? '') != null
        ? now.selectedSpaceKey
        : null;
    emit(
      ViewData(
        LayoutEditorState(
          lot: now.lot,
          base: now.base,
          draft: draft,
          selectedZoneKey: zoneKey,
          selectedSpaceKey: spaceKey,
        ),
      ),
    );
    await _save(draft);
  }

  /// Descarta el borrador y vuelve a leer la versión publicada (por ejemplo,
  /// tras un 409).
  Future<void> discard() async {
    final lot = _lot;
    if (lot == null) return;
    await _discardDraft(lot.id);
    await load(lot);
  }

  Future<void> publish() async {
    final now = current;
    if (now == null || now.publishing || now.draft.isEmpty) return;
    emit(ViewData(now.copyWith(publishing: true)));
    final result = await _publishLayout((draft: now.draft, base: now.base));
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        _notices.add(LayoutPublished(value));
        await reload();
      case Err(:final failure):
        emit(ViewData(now.copyWith(publishing: false)));
        _notices.add(LayoutPublishFailed(failure));
    }
  }

  @override
  Future<void> close() async {
    await _notices.close();
    return super.close();
  }
}
