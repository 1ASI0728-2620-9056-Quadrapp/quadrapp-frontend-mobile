import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_data.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_depth.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_inputs.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_palette.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_status.dart';
import 'package:quadrapp_mobile/app/theme/app_theme.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Ruta de la galería del sistema de diseño (solo en debug).
const galleryPath = '/gallery';

/// Galería del sistema de diseño (solo en debug, ruta `/gallery`): cada
/// componente en todos sus estados, en modo claro u oscuro.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool? _dark;

  @override
  Widget build(BuildContext context) {
    final dark =
        _dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Theme(
      data: dark ? AppTheme.dark() : AppTheme.light(),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.gallery_title)),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(QaSpacing.lg),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.gallery_darkMode),
                    value: dark,
                    onChanged: (value) => setState(() => _dark = value),
                  ),
                  const SizedBox(height: QaSpacing.lg),
                  const GalleryPalette(),
                  const GalleryDepth(),
                  const GalleryData(),
                  const GalleryStatus(),
                  const GalleryInputs(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
