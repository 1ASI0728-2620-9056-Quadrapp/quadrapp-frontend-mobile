// US04 (la sede que ve el conductor)
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Una sede en una lista de elección: su nombre, su dirección (o que todavía no
/// tiene disponibilidad publicada) y una marca si es la elegida. Es **un solo
/// objetivo táctil** de al menos 56 dp, con su `Semantics` resumido.
class SedeOption extends StatelessWidget {
  const SedeOption({
    required this.lot,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ParkingLot lot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final detail = lot.hasPublishedLayout ? lot.address : l10n.sede_noLayout;
    final summary = [
      lot.name,
      ?detail,
      if (selected) l10n.sede_current,
    ].join(', ');

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: summary,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: QaRadii.cardRadius,
          side: BorderSide(
            color: selected ? colors.primary : colors.paint,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QaSpacing.lg,
                vertical: QaSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.primary,
                  ),
                  const SizedBox(width: QaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lot.name, style: theme.textTheme.titleMedium),
                        if (detail != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              detail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: lot.hasPublishedLayout
                                    ? colors.onSurfaceMuted
                                    : colors.limitedText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: QaSpacing.md),
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
