import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _licenseAssets = {'Inter': 'fonts/licenses/Inter-OFL.txt'};

/// Registra las licencias OFL de las fuentes para que aparezcan en la pantalla
/// de licencias de Flutter (`showLicensePage`).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in _licenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
