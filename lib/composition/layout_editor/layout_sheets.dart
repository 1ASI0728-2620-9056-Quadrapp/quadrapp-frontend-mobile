// US17
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El texto de un rechazo del borrador.
String draftErrorText(AppLocalizations l10n, DraftError error) =>
    switch (error) {
      DraftError.zoneNameRequired => l10n.layout_errorZoneName,
      DraftError.zoneNameTooLong => l10n.layout_errorZoneNameLong,
      DraftError.zoneNameTaken => l10n.layout_errorZoneTaken,
      DraftError.levelNameTooLong => l10n.layout_errorGeneric,
      DraftError.spacesOutOfRange => l10n.layout_errorSpaces,
      DraftError.zoneRequired => l10n.layout_errorZone,
      DraftError.levelRequired => l10n.layout_errorLevel,
      DraftError.labelRequired => l10n.layout_errorLabel,
      DraftError.labelTooLong => l10n.layout_errorLabelLong,
      DraftError.labelTaken => l10n.layout_errorLabelTaken,
      DraftError.spaceNotFound => l10n.layout_errorGeneric,
    };

/// Botones del pie de las ventanas: la acción primaria y «Cancelar».
class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.label,
    required this.icon,
    required this.onSubmit,
    required this.busy,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onSubmit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QaButton(
          label: label,
          icon: icon,
          expand: true,
          isLoading: busy,
          onPressed: onSubmit,
        ),
        const SizedBox(height: QaSpacing.sm),
        QaButton(
          label: l10n.layout_cancel,
          variant: QaButtonVariant.text,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- añadir zona

/// Abre «Añadir zona». [onSubmit] aplica el cambio al borrador y devuelve el
/// motivo si se rechaza (la ventana sigue abierta y lo dice en su campo).
Future<void> showAddZoneSheet(
  BuildContext context, {
  required int draftVersion,
  required Future<DraftError?> Function({
    required String name,
    required String levelName,
    required int initialSpaces,
  })
  onSubmit,
}) {
  return showQaBottomSheet<void>(
    context,
    builder: (_) =>
        _AddZoneSheet(draftVersion: draftVersion, onSubmit: onSubmit),
  );
}

class _AddZoneSheet extends StatefulWidget {
  const _AddZoneSheet({required this.draftVersion, required this.onSubmit});

  final int draftVersion;
  final Future<DraftError?> Function({
    required String name,
    required String levelName,
    required int initialSpaces,
  })
  onSubmit;

  @override
  State<_AddZoneSheet> createState() => _AddZoneSheetState();
}

class _AddZoneSheetState extends State<_AddZoneSheet> {
  final _name = TextEditingController();
  final _spaces = TextEditingController(text: '20');
  int _level = 0;
  DraftError? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _spaces.dispose();
    super.dispose();
  }

  List<String> _levels(AppLocalizations l10n) => [
    l10n.layout_levelSurface,
    for (var n = 1; n <= 3; n++) l10n.layout_levelBasement(n),
    for (var n = 1; n <= 3; n++) l10n.layout_levelFloor(n),
  ];

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final error = await widget.onSubmit(
      name: _name.text,
      levelName: _levels(l10n)[_level],
      initialSpaces: int.tryParse(_spaces.text.trim()) ?? 0,
    );
    if (!mounted) return;
    if (error == null) {
      QaHaptics.confirm();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levels = _levels(l10n);
    final error = _error;
    final nameError =
        error == DraftError.zoneNameRequired ||
            error == DraftError.zoneNameTooLong ||
            error == DraftError.zoneNameTaken
        ? draftErrorText(l10n, error!)
        : null;
    final spacesError = error == DraftError.spacesOutOfRange
        ? draftErrorText(l10n, error!)
        : null;
    return QaBottomSheet(
      title: l10n.layout_addZone,
      subtitle: l10n.layout_sheetSubtitle(widget.draftVersion),
      closeLabel: l10n.layout_close,
      footer: _SheetFooter(
        label: l10n.layout_addToDraft,
        icon: Icons.add_rounded,
        busy: _busy,
        onSubmit: () => unawaited(_submit()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaTextField(
            label: l10n.layout_zoneName,
            controller: _name,
            errorText: nameError,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(LayoutDraft.maxZoneName),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          _LabeledDropdown<int>(
            label: l10n.layout_level,
            helper: l10n.layout_levelHelp,
            value: _level,
            items: [
              for (var i = 0; i < levels.length; i++) (i, levels[i]),
            ],
            onChanged: (value) => setState(() => _level = value ?? 0),
          ),
          const SizedBox(height: QaSpacing.lg),
          QaTextField(
            label: l10n.layout_initialSpaces,
            controller: _spaces,
            helperText: l10n.layout_initialSpacesHelp,
            errorText: spacesError,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.info,
            icon: Icons.info_outline_rounded,
            message: l10n.layout_addZoneNote,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------- añadir/editar espacio

/// Lo que devuelve la ventana de espacio al confirmar.
typedef SpaceForm = ({
  String? zoneKey,
  String? levelKey,
  String label,
  SpaceType type,
  bool enabled,
});

/// Abre «Añadir espacio» o, con [editing], «Editar espacio» (la zona no se
/// cambia y no hay interruptor: para sacarlo del aforo está «Deshabilitar»).
/// [suggest] da el siguiente código libre de una zona.
Future<void> showSpaceSheet(
  BuildContext context, {
  required DraftLayout layout,
  required int draftVersion,
  required String Function(String zoneKey) suggest,
  required Future<DraftError?> Function(SpaceForm form) onSubmit,
  String? initialZoneKey,
  DraftSpace? editing,
}) {
  return showQaBottomSheet<void>(
    context,
    builder: (_) => _SpaceSheet(
      layout: layout,
      draftVersion: draftVersion,
      suggest: suggest,
      onSubmit: onSubmit,
      initialZoneKey: initialZoneKey,
      editing: editing,
    ),
  );
}

class _SpaceSheet extends StatefulWidget {
  const _SpaceSheet({
    required this.layout,
    required this.draftVersion,
    required this.suggest,
    required this.onSubmit,
    this.initialZoneKey,
    this.editing,
  });

  final DraftLayout layout;
  final int draftVersion;
  final String Function(String zoneKey) suggest;
  final Future<DraftError?> Function(SpaceForm form) onSubmit;
  final String? initialZoneKey;
  final DraftSpace? editing;

  @override
  State<_SpaceSheet> createState() => _SpaceSheetState();
}

class _SpaceSheetState extends State<_SpaceSheet> {
  late final TextEditingController _label;
  String? _zoneKey;
  String? _levelKey;
  late SpaceType _type;
  bool _enabled = true;
  String _suggested = '';
  DraftError? _error;
  bool _busy = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _type = editing?.type ?? SpaceType.standard;
    _zoneKey = editing != null
        ? widget.layout.zoneOf(editing.key)?.key
        : widget.initialZoneKey ?? widget.layout.zones.firstOrNull?.key;
    _suggested = _zoneKey == null ? '' : widget.suggest(_zoneKey!);
    _label = TextEditingController(text: editing?.label ?? _suggested);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _pickZone(String? key) {
    setState(() {
      // Si el código era la sugerencia, sigue a la zona nueva.
      final followSuggestion = _label.text == _suggested;
      _zoneKey = key;
      _levelKey = null;
      _suggested = key == null ? '' : widget.suggest(key);
      if (followSuggestion) _label.text = _suggested;
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final zone = _zoneKey == null ? null : widget.layout.zone(_zoneKey!);
    final error = await widget.onSubmit((
      zoneKey: _zoneKey,
      levelKey: _levelKey ?? zone?.levels.firstOrNull?.key,
      label: _label.text,
      type: _type,
      enabled: _enabled,
    ));
    if (!mounted) return;
    if (error == null) {
      QaHaptics.confirm();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final zone = _zoneKey == null ? null : widget.layout.zone(_zoneKey!);
    final error = _error;
    String? errorFor(Set<DraftError> errors) =>
        error != null && errors.contains(error)
        ? draftErrorText(l10n, error)
        : null;

    return QaBottomSheet(
      title: _isEdit ? l10n.layout_editSpaceTitle : l10n.layout_addSpace,
      subtitle: l10n.layout_sheetSubtitle(widget.draftVersion),
      closeLabel: l10n.layout_close,
      footer: _SheetFooter(
        label: _isEdit ? l10n.layout_saveSpace : l10n.layout_addSpace,
        icon: _isEdit ? null : Icons.add_rounded,
        busy: _busy,
        onSubmit: () => unawaited(_submit()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEdit)
            Text(
              zone?.name ?? '',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            )
          else
            _LabeledDropdown<String>(
              label: l10n.layout_zoneField,
              error: errorFor({DraftError.zoneRequired}),
              value: _zoneKey,
              items: [for (final z in widget.layout.zones) (z.key, z.name)],
              onChanged: _pickZone,
            ),
          if (!_isEdit && zone != null && zone.levels.length > 1) ...[
            const SizedBox(height: QaSpacing.lg),
            _LabeledDropdown<String>(
              // La zona cambia: la lista empieza de nuevo en su primer nivel.
              key: ValueKey(zone.key),
              label: l10n.layout_levelField,
              error: errorFor({DraftError.levelRequired}),
              value: _levelKey ?? zone.levels.first.key,
              items: [for (final l in zone.levels) (l.key, l.name)],
              onChanged: (value) => setState(() => _levelKey = value),
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          QaTextField(
            label: l10n.layout_label,
            controller: _label,
            helperText: _suggested.isEmpty
                ? null
                : l10n.layout_labelHelp(_suggested),
            errorText: errorFor({
              DraftError.labelRequired,
              DraftError.labelTooLong,
              DraftError.labelTaken,
            }),
            inputFormatters: [
              LengthLimitingTextInputFormatter(LayoutDraft.maxLabel),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          Text(l10n.layout_type, style: theme.textTheme.labelLarge),
          const SizedBox(height: QaSpacing.sm),
          QaSegmentedToggle<SpaceType>(
            segments: [
              QaSegment(
                value: SpaceType.standard,
                label: l10n.layout_typeStandard,
              ),
              QaSegment(
                value: SpaceType.accessible,
                label: l10n.layout_typeAccessible,
                icon: Icons.accessible_rounded,
              ),
            ],
            selected: _type,
            onChanged: (type) => setState(() => _type = type),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: QaSpacing.lg),
            QaSwitchRow(
              icon: Icons.check_circle_outline_rounded,
              title: l10n.layout_enabledTitle,
              help: l10n.layout_enabledHelp,
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: QaSpacing.lg),
            QaBanner(
              kind: QaBannerKind.info,
              icon: Icons.info_outline_rounded,
              message: l10n.layout_addSpaceNote,
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ publicar

/// «¿Publicar versión N?» con el antes y el después. Devuelve `true` si se
/// confirma.
Future<bool> showPublishDialog(
  BuildContext context, {
  required int version,
  required PublishSummary summary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _PublishDialog(version: version, summary: summary),
  );
  return confirmed ?? false;
}

class _PublishDialog extends StatelessWidget {
  const _PublishDialog({required this.version, required this.summary});

  final int version;
  final PublishSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    String change(int before, int after) =>
        before == after ? l10n.layout_rowNoChanges(after) : '$before → $after';

    final rows = <(String, String)>[
      (l10n.layout_rowZones, change(summary.zonesBefore, summary.zonesAfter)),
      (
        l10n.layout_rowSpaces,
        change(summary.spacesBefore, summary.spacesAfter),
      ),
      if (summary.disabledLabels.isNotEmpty)
        (l10n.layout_rowDisabled, summary.disabledLabels.join(', ')),
    ];

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: QaSpacing.lg,
        vertical: QaSpacing.xl,
      ),
      icon: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: QaRadii.controlRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.sm),
            child: Icon(Icons.upload_rounded, color: colors.primary),
          ),
        ),
      ),
      title: Text(l10n.layout_publishDialogTitle(version)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.layout_publishDialogMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: QaSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: QaRadii.controlRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QaSpacing.md,
                  vertical: QaSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final (label, value) in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: QaSpacing.sm,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: QaSpacing.md),
                            Flexible(
                              child: Text(
                                value,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QaSpacing.md),
            Text(
              l10n.layout_publishDialogNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: QaSpacing.sm,
      actions: [
        QaButton(
          label: l10n.layout_keepEditing,
          variant: QaButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        QaButton(
          label: l10n.layout_publishConfirm,
          onPressed: () {
            QaHaptics.confirm();
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}

/// Una lista desplegable con la etiqueta arriba, la ayuda y el error debajo,
/// como `QaTextField`.
class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helper,
    this.error,
    super.key,
  });

  final String label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final helper = this.helper;
    final error = this.error;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: QaSpacing.lg,
                vertical: QaSpacing.md,
              ),
            ),
            items: [
              for (final (itemValue, text) in items)
                DropdownMenuItem(value: itemValue, child: Text(text)),
            ],
            onChanged: onChanged,
          ),
          if (error != null) ...[
            const SizedBox(height: QaSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 16, color: colors.full),
                const SizedBox(width: QaSpacing.sm),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.full,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (helper != null) ...[
            const SizedBox(height: QaSpacing.xs),
            Text(
              helper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
