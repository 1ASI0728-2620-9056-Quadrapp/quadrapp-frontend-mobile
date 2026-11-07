// El campo privado _semanticLabel no puede ser un parámetro inicializador
// con nombre público, y se quiere que el constructor de carga lo exija.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_freshness_label.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_skeleton.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_tone_glyph.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

enum _KpiStatus { data, loading, empty, error }

/// Indicador numérico con cinco estados: éxito (por defecto), cargando
/// ([QaKpi.loading]), vacío ([QaKpi.empty]), error ([QaKpi.error]) y
/// desactualizado (`staleLabel`).
class QaKpi extends StatelessWidget {
  const QaKpi({
    required this.label,
    required this.value,
    this.caption,
    this.tone,
    this.staleLabel,
    super.key,
  }) : _status = _KpiStatus.data,
       _message = null,
       _semanticLabel = null;

  const QaKpi.loading({
    required this.label,
    required String semanticLabel,
    super.key,
  }) : value = null,
       caption = null,
       tone = null,
       staleLabel = null,
       _status = _KpiStatus.loading,
       _message = null,
       _semanticLabel = semanticLabel;

  const QaKpi.empty({
    required this.label,
    required String emptyText,
    super.key,
  }) : value = null,
       caption = null,
       tone = null,
       staleLabel = null,
       _status = _KpiStatus.empty,
       _message = emptyText,
       _semanticLabel = null;

  const QaKpi.error({
    required this.label,
    required String errorText,
    super.key,
  }) : value = null,
       caption = null,
       tone = null,
       staleLabel = null,
       _status = _KpiStatus.error,
       _message = errorText,
       _semanticLabel = null;

  final String label;

  /// Cifra ya formateada (por ejemplo "34").
  final String? value;

  /// Texto secundario (por ejemplo "de 120").
  final String? caption;

  /// Tono opcional para la cifra (con su forma).
  final QaTone? tone;

  /// Si no es nulo, el dato está desactualizado y se muestra este texto.
  final String? staleLabel;

  final _KpiStatus _status;
  final String? _message;
  final String? _semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final numberStyle = theme.textTheme.displaySmall;

    final body = switch (_status) {
      _KpiStatus.loading => QaLoadingRegion(
        semanticLabel: _semanticLabel!,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QaSkeleton(width: 72, height: 36),
            SizedBox(height: QaSpacing.sm),
            QaSkeleton.line(width: 96),
          ],
        ),
      ),
      _KpiStatus.empty => Text(
        '—  $_message',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
      _KpiStatus.error => Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.full),
          const SizedBox(width: QaSpacing.sm),
          Expanded(
            child: Text(
              _message!,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.full),
            ),
          ),
        ],
      ),
      _KpiStatus.data => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (tone != null) ...[
                QaToneGlyph(tone: tone!, size: 16),
                const SizedBox(width: QaSpacing.sm),
              ],
              Flexible(
                child: Text(
                  value ?? '',
                  style: numberStyle?.copyWith(
                    color: staleLabel != null
                        ? colors.onSurfaceMuted
                        : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (caption != null)
            Text(
              caption!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          if (staleLabel != null) ...[
            const SizedBox(height: QaSpacing.xs),
            QaFreshnessLabel(label: staleLabel!, isStale: true),
          ],
        ],
      ),
    };

    return Semantics(
      container: true,
      label: switch (_status) {
        _KpiStatus.data => [
          label,
          value,
          caption,
          staleLabel,
        ].whereType<String>().join(', '),
        _KpiStatus.loading => '$label, $_semanticLabel',
        _ => '$label, $_message',
      },
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: QaRadii.cardRadius,
            border: Border.all(color: colors.paint),
          ),
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: QaSpacing.xs),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
