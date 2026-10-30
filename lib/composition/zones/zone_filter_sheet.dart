// US06
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// «Ordenar y filtrar» de Zonas: el orden de los pabellones y si se ocultan los
/// que no tienen espacios libres. Los cambios se aplican al momento
/// ([onChanged]); «Listo» solo cierra la ventana.
Future<void> showZoneFilterSheet(
  BuildContext context, {
  required ZoneListOptions initial,
  required ValueChanged<ZoneListOptions> onChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return showQaBottomSheet<void>(
    context,
    builder: (sheetContext) => _FilterSheet(
      initial: initial,
      onChanged: onChanged,
      title: l10n.zones_filterTitle,
      closeLabel: l10n.zones_filterClose,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.onChanged,
    required this.title,
    required this.closeLabel,
  });

  final ZoneListOptions initial;
  final ValueChanged<ZoneListOptions> onChanged;
  final String title;
  final String closeLabel;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ZoneListOptions _options = widget.initial;

  void _set(ZoneListOptions options) {
    setState(() => _options = options);
    widget.onChanged(options);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return QaBottomSheet(
      title: widget.title,
      closeLabel: widget.closeLabel,
      footer: Row(
        children: [
          QaButton(
            label: l10n.zones_filterReset,
            variant: QaButtonVariant.tonal,
            onPressed: _options.isDefault
                ? null
                : () => _set(const ZoneListOptions()),
          ),
          const SizedBox(width: QaSpacing.md),
          Expanded(
            child: QaButton(
              label: l10n.zones_filterDone,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.zones_orderLabel,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          _ChoiceTile(
            label: l10n.zones_orderByName,
            selected: _options.order == ZoneOrder.byName,
            onTap: () => _set(_options.copyWith(order: ZoneOrder.byName)),
          ),
          _ChoiceTile(
            label: l10n.zones_orderMostFree,
            selected: _options.order == ZoneOrder.mostFree,
            onTap: () => _set(_options.copyWith(order: ZoneOrder.mostFree)),
          ),
          const SizedBox(height: QaSpacing.md),
          // El fondo de la ventana tapa la tinta de `ListTile`: lleva su propio
          // `Material`.
          Material(
            type: MaterialType.transparency,
            child: MergeSemantics(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.zones_onlyFree),
                value: _options.onlyWithFree,
                onChanged: (value) =>
                    _set(_options.copyWith(onlyWithFree: value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opción excluyente: marca (ícono) y texto, nunca solo color.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: QaRadii.controlRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QaSpacing.minTapTarget),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceMuted,
              ),
              const SizedBox(width: QaSpacing.md),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
