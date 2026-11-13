// US17 (editar la distribución, solo el administrador de universidad)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/layout_editor/layout_editor_cubit.dart';
import 'package:quadrapp_mobile/composition/layout_editor/layout_plan_card.dart';
import 'package:quadrapp_mobile/composition/layout_editor/layout_sheets.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// «Editar distribución» (`/ops/zones/layout`, solo `ADMIN`): el plano del
/// estacionamiento elegido, añadir zonas y espacios, editar o deshabilitar un
/// espacio, deshacer y publicar la nueva versión. Los cambios forman un
/// borrador guardado en el teléfono que nadie más ve hasta publicar.
///
/// Cinco estados: skeleton al cargar, sin zonas (invita a añadir la primera),
/// error recuperable, borrador descartado o publicación fallida (avisos) y
/// éxito. Al publicar, Estacionamientos se recarga.
class LayoutEditorPage extends StatefulWidget {
  const LayoutEditorPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<LayoutEditorPage> createState() => _LayoutEditorPageState();
}

class _LayoutEditorPageState extends State<LayoutEditorPage> {
  StreamSubscription<LayoutEditorNotice>? _notices;
  Failure? _publishFailure;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<LayoutEditorCubit>();
    _notices = cubit.notices.listen(_onNotice);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLot(context.read<SedeCubit>().state);
    });
  }

  @override
  void dispose() {
    unawaited(_notices?.cancel());
    super.dispose();
  }

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  void _syncLot(ViewState<SedeSelection> state) {
    final lot = _selectedOf(state);
    if (lot != null) {
      setState(() => _publishFailure = null);
      unawaited(context.read<LayoutEditorCubit>().load(lot));
    }
  }

  void _onNotice(LayoutEditorNotice notice) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (notice) {
      case LayoutPublished(:final version):
        setState(() => _publishFailure = null);
        showQaSnackbar(context, message: l10n.layout_published(version));
        // Estacionamientos y el selector ven la versión nueva.
        unawaited(context.read<ZonesCubit>().refresh());
        unawaited(context.read<SedeCubit>().load());
      case LayoutPublishFailed(:final failure):
        setState(() => _publishFailure = failure);
      case LayoutDraftDiscarded():
        showQaSnackbar(
          context,
          message: l10n.layout_draftDiscarded,
          icon: Icons.info_outline_rounded,
        );
      case LayoutDraftNotSaved():
        showQaSnackbar(
          context,
          message: l10n.layout_saveFailed,
          icon: Icons.warning_amber_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<SedeCubit, ViewState<SedeSelection>>(
      listenWhen: (before, after) =>
          _selectedOf(before)?.id != _selectedOf(after)?.id,
      listener: (context, state) => _syncLot(state),
      child: QaTabPage(
        title: l10n.layout_title,
        onBack: widget.onBack,
        backLabel: l10n.common_back,
        children: [
          SedeGate(
            skeleton: _skeleton(l10n),
            builder: (context, lot) =>
                BlocBuilder<LayoutEditorCubit, ViewState<LayoutEditorState>>(
                  builder: (context, state) => switch (state) {
                    ViewData(:final data) => _content(context, l10n, data),
                    ViewError(:final failure) => QaErrorState(
                      title: l10n.layout_errorTitle,
                      message: loadErrorText(l10n, failure),
                      retryLabel: l10n.lots_retry,
                      onRetry: () => unawaited(
                        context.read<LayoutEditorCubit>().reload(),
                      ),
                    ),
                    _ => _skeleton(l10n),
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    LayoutEditorState state,
  ) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final cubit = context.read<LayoutEditorCubit>();
    final layout = state.layout;
    final draft = state.draft;
    final hasChanges = !draft.isEmpty;

    final QaTone chipTone;
    final String chipText;
    if (hasChanges) {
      chipTone = QaTone.limited;
      chipText = l10n.layout_draftChip(draft.targetVersion);
    } else if (state.base == null) {
      chipTone = QaTone.unknown;
      chipText = l10n.layout_noLayoutChip;
    } else {
      chipTone = QaTone.free;
      chipText = l10n.layout_publishedChip(draft.baseVersion);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.layout_subtitle(state.lot.name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: QaSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: QaStatusChip(tone: chipTone, label: chipText),
            ),
            TextButton.icon(
              onPressed: hasChanges
                  ? () {
                      unawaited(cubit.undo());
                      showQaSnackbar(
                        context,
                        message: l10n.layout_undone,
                        icon: Icons.undo_rounded,
                      );
                    }
                  : null,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, QaSpacing.minTapTarget),
              ),
              icon: const Icon(Icons.undo_rounded),
              label: Text(l10n.layout_undo),
            ),
          ],
        ),
        if (_publishFailure != null) ...[
          const SizedBox(height: QaSpacing.md),
          _failureBanner(l10n, _publishFailure!, cubit),
        ],
        const SizedBox(height: QaSpacing.md),
        LayoutPlanCard(
          layout: layout,
          selectedZoneKey: state.selectedZoneKey,
          selectedSpaceKey: state.selectedSpaceKey,
          onSelectZone: cubit.selectZone,
          onSelectSpace: cubit.selectSpace,
        ),
        const SizedBox(height: QaSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final addZone = QaButton(
              label: l10n.layout_addZone,
              icon: Icons.add_rounded,
              variant: QaButtonVariant.tonal,
              expand: true,
              onPressed: () => unawaited(
                showAddZoneSheet(
                  context,
                  draftVersion: draft.targetVersion,
                  onSubmit: cubit.addZone,
                ),
              ),
            );
            final addSpace = QaButton(
              label: l10n.layout_addSpace,
              icon: Icons.add_rounded,
              variant: QaButtonVariant.tonal,
              expand: true,
              onPressed: layout.zones.isEmpty
                  ? null
                  : () => unawaited(
                      showSpaceSheet(
                        context,
                        layout: layout,
                        draftVersion: draft.targetVersion,
                        initialZoneKey: state.selectedZoneKey,
                        suggest: (zoneKey) =>
                            draft.suggestLabel(state.base, zoneKey),
                        onSubmit: (form) => cubit.addSpace(
                          zoneKey: form.zoneKey,
                          levelKey: form.levelKey,
                          label: form.label,
                          type: form.type,
                          enabled: form.enabled,
                        ),
                      ),
                    ),
            );
            // Lado a lado como el diseño; apilados si no caben sin cortar
            // el texto.
            final stacked =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(16) >= 22;
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      addZone,
                      const SizedBox(height: QaSpacing.sm),
                      addSpace,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: addZone),
                      const SizedBox(width: QaSpacing.sm),
                      Expanded(child: addSpace),
                    ],
                  );
          },
        ),
        const SizedBox(height: QaSpacing.md),
        _selectedSpaceCard(context, l10n, state),
        const SizedBox(height: QaSpacing.md),
        _publishCard(context, l10n, state),
      ],
    );
  }

  Widget _failureBanner(
    AppLocalizations l10n,
    Failure failure,
    LayoutEditorCubit cubit,
  ) {
    return switch (failure) {
      ValidationFailure() => QaBanner(
        kind: QaBannerKind.error,
        message: l10n.layout_conflict,
        actionLabel: l10n.layout_discard,
        onAction: () => unawaited(cubit.discard()),
      ),
      ForbiddenFailure() => QaBanner(
        kind: QaBannerKind.error,
        message: l10n.layout_forbidden,
      ),
      _ => QaBanner(
        kind: QaBannerKind.error,
        message: l10n.layout_publishError,
      ),
    };
  }

  Widget _selectedSpaceCard(
    BuildContext context,
    AppLocalizations l10n,
    LayoutEditorState state,
  ) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final cubit = context.read<LayoutEditorCubit>();
    final space = state.selectedSpace;
    if (space == null) {
      return QaCard(
        child: Text(
          l10n.layout_noSpaceSelected,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
      );
    }
    final zone = state.layout.zoneOf(space.key);
    final details = [
      if (space.type == SpaceType.accessible)
        l10n.layout_spaceAccessible
      else
        l10n.layout_spaceStandard,
      if (!space.enabled)
        l10n.layout_spaceDisabled
      else if (space.isNew)
        l10n.layout_spaceNew
      else
        l10n.layout_spaceEnabled,
      if (space.isEdited && !space.isNew) l10n.layout_spaceEdited,
    ].join(' · ');

    void edit() => unawaited(
      showSpaceSheet(
        context,
        layout: state.layout,
        draftVersion: state.draft.targetVersion,
        editing: space,
        suggest: (zoneKey) => state.draft.suggestLabel(state.base, zoneKey),
        onSubmit: (form) => cubit.editSpace(
          spaceKey: space.key,
          label: form.label,
          type: form.type,
        ),
      ),
    );

    Future<void> disable() async {
      final enabledNow = zone?.enabledCount ?? 0;
      final confirmed = await showQaConfirmDialog(
        context,
        title: l10n.layout_disableTitle(space.label),
        subject: l10n.layout_spaceTitle(zone?.name ?? '', space.label),
        message: l10n.layout_disableMessage(
          zone?.name ?? '',
          enabledNow,
          enabledNow - 1,
          state.draft.targetVersion,
        ),
        confirmLabel: l10n.layout_disableConfirm,
        cancelLabel: l10n.layout_cancel,
        icon: Icons.warning_amber_rounded,
        destructive: true,
      );
      if (confirmed) {
        await cubit.setEnabled(space.key, enabled: false);
      }
    }

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.layout_spaceTitle(zone?.name ?? '', space.label),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.layout_editData,
                onPressed: edit,
                icon: Icon(Icons.edit_outlined, color: colors.primary),
              ),
            ],
          ),
          Text(
            details,
            style: theme.textTheme.bodySmall?.copyWith(
              color: space.enabled ? colors.onSurfaceMuted : colors.full,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: QaSpacing.sm,
            children: [
              TextButton(
                onPressed: edit,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, QaSpacing.minTapTarget),
                ),
                child: Text(l10n.layout_editData),
              ),
              if (space.enabled)
                TextButton(
                  onPressed: () => unawaited(disable()),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.full,
                    minimumSize: const Size(0, QaSpacing.minTapTarget),
                  ),
                  child: Text(l10n.layout_disable),
                )
              else
                TextButton(
                  onPressed: () =>
                      unawaited(cubit.setEnabled(space.key, enabled: true)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, QaSpacing.minTapTarget),
                  ),
                  child: Text(l10n.layout_enable),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _publishCard(
    BuildContext context,
    AppLocalizations l10n,
    LayoutEditorState state,
  ) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final cubit = context.read<LayoutEditorCubit>();
    final layout = state.layout;
    final draft = state.draft;
    final zones = l10n.layout_zonesCount(layout.zones.length);
    final spaces = l10n.layout_zoneSpaces(layout.enabledCount);

    Future<void> publish() async {
      final confirmed = await showPublishDialog(
        context,
        version: draft.targetVersion,
        summary: draft.summary(state.base),
      );
      if (confirmed) {
        setState(() => _publishFailure = null);
        await cubit.publish();
      }
    }

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.layout_publishTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: QaSpacing.xs),
          Text(
            draft.isEmpty
                ? l10n.layout_publishNothing(zones, spaces)
                : l10n.layout_publishReady(zones, spaces),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          QaButton(
            label: l10n.layout_publishAction(draft.targetVersion),
            icon: Icons.upload_rounded,
            expand: true,
            isLoading: state.publishing,
            loadingLabel: l10n.layout_publishing,
            onPressed: draft.isEmpty ? null : () => unawaited(publish()),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(AppLocalizations l10n) => QaLoadingRegion(
    semanticLabel: l10n.layout_loading,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QaSkeleton.line(width: 180),
        SizedBox(height: QaSpacing.md),
        QaSkeleton(width: 160, height: 32),
        SizedBox(height: QaSpacing.md),
        QaSkeleton(height: 220, borderRadius: QaRadii.cardRadius),
        SizedBox(height: QaSpacing.md),
        QaSkeleton(height: 48),
        SizedBox(height: QaSpacing.md),
        QaSkeleton(height: 120, borderRadius: QaRadii.cardRadius),
      ],
    ),
  );
}
