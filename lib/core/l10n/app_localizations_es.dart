// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get common_appName => 'Quadrapp';

  @override
  String get common_back => 'Atrás';

  @override
  String get gallery_title => 'Sistema de diseño';

  @override
  String get gallery_cardLow => 'Elevación baja';

  @override
  String get gallery_cardHigh => 'Elevación alta';

  @override
  String get gallery_cardTap => 'Tócame: la tarjeta se encoge a 0,98';

  @override
  String get gallery_heroTitle => 'Superficie héroe';

  @override
  String get gallery_heroFree => 'libres';

  @override
  String get gallery_liveLive => 'En vivo';

  @override
  String get gallery_liveReconnecting => 'Reconectando…';

  @override
  String get gallery_liveOffline => 'Sin conexión';

  @override
  String get gallery_openSheet => 'Abrir ventana inferior';

  @override
  String get gallery_sheetTitle => 'Elemento nuevo';

  @override
  String get gallery_sheetBody =>
      'El cuerpo se desplaza; la acción principal queda fija abajo, incluso con el teclado abierto.';

  @override
  String get gallery_sheetAction => 'Guardar';

  @override
  String get gallery_sheetClose => 'Cerrar';

  @override
  String get gallery_openConfirm => 'Abrir diálogo de confirmación';

  @override
  String get gallery_confirmTitle => '¿Dar de baja el dispositivo?';

  @override
  String get gallery_confirmSubject => 'SENS-A-18 · Espacio A-18';

  @override
  String get gallery_confirmMessage =>
      'Dejará de enviar eventos. No se puede deshacer.';

  @override
  String get gallery_confirmAction => 'Dar de baja';

  @override
  String get gallery_openSnack => 'Mostrar aviso con Deshacer';

  @override
  String get gallery_snackMessage => 'Alerta guardada';

  @override
  String get gallery_snackUndo => 'Deshacer';

  @override
  String get gallery_open => 'Abrir galería del sistema de diseño';

  @override
  String get gallery_darkMode => 'Modo oscuro';

  @override
  String get gallery_stateLoading => 'Cargando';

  @override
  String get gallery_stateEmpty => 'Vacío';

  @override
  String get gallery_stateError => 'Error';

  @override
  String get gallery_statePartial => 'Parcial o desactualizado';

  @override
  String get gallery_stateSuccess => 'Éxito';

  @override
  String get gallery_stateDisabled => 'Deshabilitado';

  @override
  String get gallery_stateFilled => 'Con contenido';

  @override
  String get gallery_buttonPrimary => 'Enviar código';

  @override
  String get gallery_buttonTonal => 'Guardar preferencias';

  @override
  String get gallery_buttonText => 'Cambiar mi tiempo de llegada';

  @override
  String get gallery_buttonDestructive => 'Cerrar sesión';

  @override
  String get gallery_fieldLabel => 'Correo institucional';

  @override
  String get gallery_fieldHint => 'nombre@universidad.edu';

  @override
  String get gallery_fieldHelper => 'Te enviaremos un código de un solo uso.';

  @override
  String get gallery_fieldError => 'Ingresa un correo institucional válido.';

  @override
  String get gallery_otpLabel => 'Código de verificación, 6 dígitos';

  @override
  String get gallery_otpError =>
      'El código venció o no coincide. Pide uno nuevo.';

  @override
  String get gallery_statusFree => 'Libre';

  @override
  String get gallery_statusLimited => 'Limitada';

  @override
  String get gallery_statusOccupied => 'Ocupado';

  @override
  String get gallery_statusUnknown => 'Sin datos';

  @override
  String gallery_plateHeadline(int minutes) {
    return 'Llegas en $minutes min';
  }

  @override
  String get gallery_plateHigh => 'Alta';

  @override
  String get gallery_plateLimited => 'Limitada';

  @override
  String get gallery_plateLow => 'Baja';

  @override
  String gallery_plateDetail(int percent) {
    return '$percent % de probabilidad de encontrar espacio';
  }

  @override
  String gallery_plateFootnote(String confidence, String time) {
    return '$confidence · $time';
  }

  @override
  String get gallery_confidenceHigh => 'Confianza alta';

  @override
  String get gallery_confidenceMedium => 'Confianza media';

  @override
  String get gallery_confidenceLow => 'Confianza baja';

  @override
  String get gallery_confidenceLowNote => 'Estimación con pocos datos';

  @override
  String gallery_freshnessFresh(int seconds) {
    return 'Actualizado hace $seconds s';
  }

  @override
  String gallery_freshnessStale(String time) {
    return 'Sin datos nuevos desde las $time';
  }

  @override
  String gallery_horizonLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String gallery_horizonValue(int percent) {
    return '$percent %';
  }

  @override
  String gallery_horizonSemantic(int minutes, int percent) {
    return 'En $minutes minutos: $percent % ocupado';
  }

  @override
  String gallery_horizonMissingSemantic(int minutes) {
    return 'En $minutes minutos: sin pronóstico';
  }

  @override
  String gallery_horizonExpiredSemantic(int minutes) {
    return 'En $minutes minutos: pronóstico vencido';
  }

  @override
  String gallery_horizonSaturation(String time) {
    return 'Se llena a las $time';
  }

  @override
  String gallery_mapSummary(int free, int occupied, int unknown) {
    return 'Mapa del estacionamiento: $free libres, $occupied ocupados, $unknown sin datos';
  }

  @override
  String gallery_zoneName(String name) {
    return 'Zona $name';
  }

  @override
  String gallery_zoneFree(int count) {
    return '$count libres';
  }

  @override
  String gallery_zoneOccupied(int count) {
    return '$count ocupados';
  }

  @override
  String gallery_zoneUnknown(int count) {
    return '$count sin datos';
  }

  @override
  String gallery_zoneSemantic(
    String name,
    int free,
    int occupied,
    int unknown,
  ) {
    return 'Zona $name: $free libres, $occupied ocupados, $unknown sin datos';
  }

  @override
  String get gallery_kpiLabel => 'Espacios libres';

  @override
  String gallery_kpiCaption(int total) {
    return 'de $total';
  }

  @override
  String get gallery_kpiEmpty => 'Aún sin datos';

  @override
  String get gallery_kpiError => 'No se pudo cargar';

  @override
  String get gallery_slotDays => 'Días';

  @override
  String get gallery_slotFrom => 'Desde';

  @override
  String get gallery_slotTo => 'Hasta';

  @override
  String get gallery_slotPick => 'Elige una hora';

  @override
  String get gallery_slotError =>
      'La hora de fin debe ser posterior a la de inicio.';

  @override
  String get gallery_dialogOpen => 'Mostrar diálogo de confirmación';

  @override
  String get gallery_dialogTitle => 'Cerrar sesión';

  @override
  String get gallery_dialogMessage =>
      'Necesitarás un código nuevo para volver a ingresar en este dispositivo.';

  @override
  String get gallery_dialogConfirm => 'Cerrar sesión';

  @override
  String get gallery_dialogCancel => 'Cancelar';

  @override
  String get gallery_emptyTitle => 'Aún no sigues ninguna franja';

  @override
  String get gallery_emptyMessage =>
      'Aún no sigues ninguna franja. Elige a qué hora sueles llegar y te avisamos si se prevé que se llene.';

  @override
  String get gallery_emptyAction => 'Suscribirme a esta franja';

  @override
  String get gallery_errorTitle => 'No se pudo cargar la disponibilidad';

  @override
  String get gallery_errorMessage =>
      'No hay conexión con el servidor. Revisa tu red e inténtalo de nuevo.';

  @override
  String get gallery_errorRetry => 'Reintentar';

  @override
  String gallery_bannerOffline(String time) {
    return 'Sin conexión. Mostramos lo último que tenemos, de las $time.';
  }

  @override
  String gallery_bannerStale(String time) {
    return 'Sin datos nuevos desde las $time. Lo que ves puede no estar al día.';
  }

  @override
  String get gallery_bannerError =>
      'El código venció o no coincide. Pide uno nuevo.';

  @override
  String get gallery_bannerInfo =>
      'Se actualizó la distribución del estacionamiento.';

  @override
  String get gallery_mapSimulate => 'Simular un cambio de espacio';

  @override
  String get iam_restoring => 'Revisando tu sesión…';

  @override
  String get iam_loginTitle => 'Anticipa tu llegada al campus';

  @override
  String get iam_loginSubtitle =>
      'Consulta la disponibilidad estimada antes de salir. Sin reservas ni pagos.';

  @override
  String get iam_emailLabel => 'Correo institucional';

  @override
  String get iam_emailHint => 'nombre@universidad.edu';

  @override
  String get iam_emailErrorEmpty => 'Ingresa tu correo institucional.';

  @override
  String get iam_emailErrorInvalid =>
      'Ingresa un correo válido, como nombre@universidad.edu.';

  @override
  String get iam_sendCode => 'Continuar';

  @override
  String get iam_sendingCode => 'Enviando código…';

  @override
  String iam_sendCodeIn(String time) {
    return 'Continuar en $time';
  }

  @override
  String get iam_rateLimited =>
      'Demasiados intentos. Podrás pedir otro código cuando termine la cuenta regresiva.';

  @override
  String get iam_errorForbidden =>
      'Ese correo no pertenece a una institución habilitada.';

  @override
  String get iam_errorEmailFormat =>
      'El formato del correo no es válido. Revísalo e inténtalo de nuevo.';

  @override
  String get iam_errorNetwork =>
      'Sin conexión. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get iam_errorGeneric =>
      'Algo salió mal de nuestro lado. Inténtalo de nuevo en un momento.';

  @override
  String get iam_retry => 'Reintentar';

  @override
  String get iam_sessionExpired =>
      'Tu sesión venció. Inicia sesión de nuevo para continuar.';

  @override
  String get iam_verifyTitle => 'Verifica tu correo';

  @override
  String iam_verifySentTo(String email) {
    return 'Enviamos un código de 6 dígitos a $email.';
  }

  @override
  String iam_verifyValidity(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'El código es válido por $minutes minutos.',
      one: 'El código es válido por 1 minuto.',
    );
    return '$_temp0';
  }

  @override
  String get iam_otpLabel => 'Código de verificación, 6 dígitos';

  @override
  String get iam_verifyAction => 'Verificar y entrar';

  @override
  String get iam_verifying => 'Verificando…';

  @override
  String get iam_errorCodeInvalid =>
      'El código venció o no coincide. Pide uno nuevo.';

  @override
  String get iam_errorCodeIncomplete => 'Ingresa los 6 dígitos.';

  @override
  String get iam_resend => 'Reenviar código';

  @override
  String iam_resendIn(String time) {
    return 'Reenviar código en $time';
  }

  @override
  String get iam_resending => 'Enviando un código nuevo…';

  @override
  String get iam_noticeResent => 'Te enviamos un código nuevo.';

  @override
  String get iam_noticeResendNetwork =>
      'No pudimos enviar un código nuevo: sin conexión.';

  @override
  String get iam_noticeResendFailed =>
      'No pudimos enviar un código nuevo. Inténtalo de nuevo en un momento.';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_alerts => 'Alertas';

  @override
  String get nav_settings => 'Ajustes';

  @override
  String get nav_shift => 'Turno';

  @override
  String get nav_lots => 'Lotes';

  @override
  String get nav_devices => 'Dispositivos';

  @override
  String get ops_shiftSoonTitle => 'La consola de turno llega pronto';

  @override
  String get ops_shiftSoonMessage =>
      'Pronto verás la capacidad, el flujo y la saturación prevista de tu estacionamiento.';

  @override
  String get ops_lotsSoonTitle => 'El resumen de lotes llega pronto';

  @override
  String get ops_lotsSoonMessage =>
      'Pronto verás cada lote con su ocupación y su estado.';

  @override
  String get ops_devicesSoonTitle => 'Los dispositivos llegan pronto';

  @override
  String get ops_devicesSoonMessage =>
      'Pronto verás la salud de cada sensor y gateway.';

  @override
  String get sede_choose => 'Elegir sede';

  @override
  String sede_chipLabel(String name) {
    return 'Sede: $name. Cambiar de sede';
  }

  @override
  String get sede_sheetTitle => 'Elige tu sede';

  @override
  String get sede_sheetSubtitle =>
      'Verás la disponibilidad de la sede que elijas.';

  @override
  String get sede_close => 'Cerrar';

  @override
  String get sede_noLayout => 'Aún sin disponibilidad publicada';

  @override
  String get sede_current => 'Sede actual';

  @override
  String get sede_promptTitle => '¿A qué sede vas?';

  @override
  String get sede_promptMessage =>
      'Elige tu sede para ver la disponibilidad de su estacionamiento.';

  @override
  String get sede_errorTitle => 'No pudimos cargar las sedes';

  @override
  String get nav_zones => 'Zonas';

  @override
  String get nav_forecast => 'Predicción';

  @override
  String get title_arrival => 'Tu llegada';

  @override
  String get title_zones => 'Estacionamiento';

  @override
  String get title_forecast => 'Predicción';

  @override
  String get title_alerts => 'Alertas y preferencias';

  @override
  String get title_account => 'Cuenta';

  @override
  String get account_open => 'Cuenta';

  @override
  String get iam_emailHelper =>
      'Usaremos tu dominio para validar el acceso de tu comunidad.';

  @override
  String get iam_privacyMinutes =>
      'Al pedir una predicción solo compartes los minutos estimados de llegada. Nunca tu ubicación.';

  @override
  String iam_legalIntro(String terms, String privacy) {
    return 'Al continuar aceptas los $terms y la $privacy.';
  }

  @override
  String get iam_legalTerms => 'Términos';

  @override
  String get iam_legalPrivacy => 'Política de privacidad';

  @override
  String get iam_verifyHeading => 'Código de verificación';

  @override
  String get iam_verifyOfflineTip =>
      'Si tu conexión se interrumpe, conservaremos el código para que puedas reintentar.';

  @override
  String get legal_title => 'Términos y privacidad';

  @override
  String get legal_intro =>
      'Un resumen corto de lo que Quadrapp hace con tus datos. Quadrapp es gratuito: no hay reservas, pagos ni tickets.';

  @override
  String get legal_receiveTitle => 'Qué recibimos';

  @override
  String get legal_receiveBody =>
      'Tu correo institucional, para comprobar que tu institución te permite entrar y para enviarte tu código de un solo uso. Tus preferencias de alertas y tus franjas horarias. Un identificador de tu dispositivo, para enviarte las alertas que elijas.';

  @override
  String get legal_neverTitle => 'Qué nunca recibimos';

  @override
  String get legal_signOutTitle => 'Cuando cierras sesión';

  @override
  String get legal_signOutBody =>
      'Quadrapp borra tu sesión, tu sede guardada y los datos que guardó en este teléfono. Solo se conserva tu idioma.';

  @override
  String get legal_note =>
      'Este resumen no reemplaza los Términos y la Política de privacidad completos publicados en el sitio web de Quadrapp.';

  @override
  String iam_maskedSpoken(String first, String domain) {
    return '$first seguido de caracteres ocultos, en $domain';
  }

  @override
  String get iam_legalOpen => 'Abre un resumen de los términos y la privacidad';

  @override
  String get eta_sheetTitle => '¿Cuándo llegas?';

  @override
  String get eta_close => 'Cerrar';

  @override
  String get eta_useLocation => 'Usar mi ubicación';

  @override
  String get eta_locationBody =>
      'Calculamos el tiempo en tu teléfono. Quadrapp solo recibe los minutos, nunca tu ubicación.';

  @override
  String get eta_locationBlocked =>
      'La ubicación está bloqueada para Quadrapp. Puedes permitirla en los ajustes del teléfono o elegir tú el tiempo.';

  @override
  String get eta_locationOff =>
      'La ubicación de tu teléfono está apagada. Enciéndela o elige tú el tiempo.';

  @override
  String get eta_noPosition =>
      'Esta sede aún no tiene posición en el mapa, así que no se puede estimar el tiempo. Elígelo tú.';

  @override
  String get eta_manualTitle => 'O elige tú el tiempo';

  @override
  String get eta_minutesUnit => 'min';

  @override
  String get eta_stepHint => 'Se ajusta de 5 en 5 minutos.';

  @override
  String eta_minutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String eta_minutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get eta_less => 'Menos tiempo';

  @override
  String get eta_more => 'Más tiempo';

  @override
  String get eta_done => 'Listo';

  @override
  String get eta_sourceManual => 'elegido por ti';

  @override
  String get eta_change => 'Cambiar el tiempo de llegada';

  @override
  String home_greeting(String period) {
    String _temp0 = intl.Intl.selectLogic(
      period,
      {
        'morning': 'Buenos días',
        'afternoon': 'Buenas tardes',
        'other': 'Buenas noches',
      },
    );
    return '$_temp0';
  }

  @override
  String home_greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_question => '¿Encontraré espacio al llegar?';

  @override
  String get home_liveOnline => 'En línea';

  @override
  String get home_liveConnecting => 'Conectando…';

  @override
  String get home_liveReconnecting => 'Reconectando…';

  @override
  String get home_liveOffline => 'Sin conexión';

  @override
  String get home_categoryHigh => 'Buena disponibilidad';

  @override
  String get home_categoryLimited => 'Disponibilidad limitada';

  @override
  String get home_categoryLow => 'Poca disponibilidad';

  @override
  String get home_categoryNone => 'Sin estimación';

  @override
  String get home_statementHigh => 'Sí, es probable que encuentres espacio.';

  @override
  String get home_statementLimited =>
      'Quizá encuentres espacio, pero no es seguro.';

  @override
  String get home_statementLow => 'Es poco probable que encuentres espacio.';

  @override
  String get home_statementNeedsEta =>
      'Dinos cuándo llegas para estimar tu disponibilidad.';

  @override
  String get home_statementUnavailable =>
      'No pudimos estimar tu disponibilidad en este momento.';

  @override
  String get home_chooseEta => 'Elegir tiempo de llegada';

  @override
  String get home_statArrive => 'Llegas en';

  @override
  String get home_statNow => 'Ahora';

  @override
  String get home_statConfidence => 'Confianza';

  @override
  String home_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String home_freeCount(int count) {
    return '$count libres';
  }

  @override
  String home_ofSpaces(int total) {
    return 'de $total espacios';
  }

  @override
  String home_ofSpacesUnknown(int total, int unknown) {
    return 'de $total espacios · $unknown sin datos';
  }

  @override
  String get home_confidenceHigh => 'Alta';

  @override
  String get home_confidenceMedium => 'Media';

  @override
  String get home_confidenceLow => 'Baja';

  @override
  String home_forecastAge(String age) {
    return 'predicción $age';
  }

  @override
  String get home_lowConfidence =>
      'Esta estimación se basa en información limitada.';

  @override
  String home_nextFree(int min, int max) {
    return 'Se espera que se libere un espacio en $min–$max min.';
  }

  @override
  String get home_nextNone =>
      'No es posible estimar la espera: no hay salidas registradas hace poco.';

  @override
  String get home_changeTitle => 'Cómo puede cambiar';

  @override
  String home_horizonSpoken(int minutes, int percent, String category) {
    return 'En $minutes min: $percent %, $category';
  }

  @override
  String home_horizonMissing(int minutes) {
    return 'En $minutes min: no disponible';
  }

  @override
  String get home_horizonsHint => 'Abre la predicción';

  @override
  String get home_privacyLine =>
      'Compartimos minutos de llegada, nunca tu ubicación.';

  @override
  String get home_pickAnother => 'Elegir otra sede';

  @override
  String get home_partialAdvice =>
      'No pudimos cargar tu estimación de llegada. Desliza hacia abajo para reintentar.';

  @override
  String get home_partialOccupancy =>
      'No pudimos cargar los espacios actuales. Desliza hacia abajo para reintentar.';

  @override
  String get home_partialForecast =>
      'Algunas predicciones no están disponibles en este momento.';

  @override
  String get lots_loading => 'Cargando estacionamientos…';

  @override
  String get lots_emptyTitle => 'Aún no hay estacionamientos';

  @override
  String get lots_emptyMessage =>
      'Tu institución todavía no configuró estacionamientos. Desliza hacia abajo para volver a revisar.';

  @override
  String get lots_errorTitle => 'No pudimos cargar los estacionamientos';

  @override
  String get lots_errorNetwork =>
      'Sin conexión. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get lots_errorGeneric =>
      'Algo salió mal de nuestro lado. Inténtalo de nuevo en un momento.';

  @override
  String get lots_retry => 'Reintentar';

  @override
  String get lots_offlineBanner =>
      'Sin conexión. Mostramos lo último que tenemos.';

  @override
  String lots_updatedAgo(String age) {
    return 'Actualizado $age';
  }

  @override
  String time_agoSeconds(int count) {
    return 'hace $count s';
  }

  @override
  String time_agoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String time_agoHours(int count) {
    return 'hace $count h';
  }

  @override
  String lots_staleSince(String time) {
    return 'Sin datos nuevos desde las $time. Lo que ves puede no estar al día.';
  }

  @override
  String get lots_noCurrentData => 'Datos no vigentes';

  @override
  String get lots_noCurrentDataHint =>
      'Este estacionamiento aún no tiene distribución publicada.';

  @override
  String get space_free => 'Libre';

  @override
  String get space_occupied => 'Ocupado';

  @override
  String get space_unknown => 'Sin datos';

  @override
  String get settings_moreSoon =>
      'Más ajustes, como las alertas y el idioma, llegan en una próxima actualización.';

  @override
  String get settings_role => 'Rol';

  @override
  String get settings_roleDriver => 'Conductor';

  @override
  String get settings_roleOperator => 'Operador';

  @override
  String get settings_roleAdmin => 'Administrador';

  @override
  String settings_accountSemantics(
    String email,
    String institution,
    String role,
  ) {
    return 'Cuenta: $email, $institution, rol $role';
  }

  @override
  String get signOut_action => 'Cerrar sesión';

  @override
  String get signOut_signingOut => 'Cerrando sesión…';

  @override
  String get signOut_confirmTitle => '¿Cerrar sesión?';

  @override
  String signOut_confirmMessage(String email) {
    return 'Cerrarás la sesión de $email en este dispositivo y necesitarás un código para volver a entrar.';
  }

  @override
  String get signOut_cancel => 'Cancelar';

  @override
  String get signOut_error =>
      'No pudimos cerrar tu sesión. Inténtalo de nuevo.';

  @override
  String get debug_open => 'Abrir controles de mocks';

  @override
  String get debug_title => 'Controles de mocks';

  @override
  String get debug_credentials =>
      'Usuarios de prueba: conductor@upc.edu.pe (conductor) y administrador@upc.edu.pe (administrador) · código 123456';

  @override
  String get debug_forceNetworkError => 'Sin red';

  @override
  String get debug_forceNetworkErrorHelp =>
      'Toda llamada falla como si el teléfono no tuviera conexión.';

  @override
  String get debug_realtimeOutage => 'Caída del tiempo real';

  @override
  String get debug_realtimeOutageHelp =>
      'La conexión en vivo se cae (el chip de estado pasa a Reconectando); las llamadas REST siguen funcionando.';

  @override
  String get debug_locationPermission => 'Permiso de ubicación';

  @override
  String get debug_locationGranted => 'Concedido';

  @override
  String get debug_locationDenied => 'Aún no concedido';

  @override
  String get debug_locationDeniedForever => 'Denegado para siempre';

  @override
  String get debug_locationOff => 'Ubicación apagada';

  @override
  String get debug_denyLocationPrompt => 'Negar el diálogo del permiso';

  @override
  String get debug_denyLocationPromptHelp =>
      'Al pedir el permiso se niega: la primera vez queda denegado y la segunda, para siempre.';

  @override
  String get debug_force401 => '401 en llamadas protegidas';

  @override
  String get debug_force401Help =>
      'Las llamadas protegidas responden 401 (token de acceso rechazado).';

  @override
  String get debug_force429 => '429 al pedir códigos';

  @override
  String get debug_force429Help =>
      'Pedir un código responde 429 con una espera de 45 segundos.';

  @override
  String get debug_sessionExpired => 'Sesión expirada';

  @override
  String get debug_sessionExpiredHelp =>
      'El token de refresco se rechaza (401): la sesión expira.';

  @override
  String get debug_forceConsole403 => '403 en las rutas de consola';

  @override
  String get debug_forceConsole403Help =>
      'El resumen de consola y los dispositivos responden 403, como para un conductor (TS17).';

  @override
  String get debug_forceConsolePartial => 'Resumen de consola parcial';

  @override
  String get debug_forceConsolePartialHelp =>
      'El resumen responde 200 sin la saturación prevista (TS17 escenario 3).';

  @override
  String get debug_forceDeviceRegisterFailure =>
      'El registro de dispositivos falla';

  @override
  String get debug_forceDeviceRegisterFailureHelp =>
      'Registrar un dispositivo responde un error del servidor (500).';

  @override
  String get debug_actions => 'Acciones';

  @override
  String get debug_expireNow => 'Expirar la sesión ahora';

  @override
  String get debug_probe => 'Llamar a un endpoint protegido';

  @override
  String get debug_resultRefreshed => 'La sesión se renovó.';

  @override
  String debug_resultOk(int count) {
    return 'Llamada protegida correcta: $count estacionamientos.';
  }

  @override
  String debug_resultFailure(String type) {
    return 'Falló: $type';
  }

  @override
  String get debug_resetData => 'Restablecer datos';

  @override
  String get debug_resultReset => 'Datos de prueba restablecidos.';

  @override
  String get debug_resultLabel => 'Último resultado';

  @override
  String get zones_filterAction => 'Ordenar y filtrar';

  @override
  String get zones_filterActionActive => 'Ordenar y filtrar, activo';

  @override
  String get zones_filterTitle => 'Ordenar y filtrar';

  @override
  String get zones_filterClose => 'Cerrar';

  @override
  String get zones_orderLabel => 'Orden';

  @override
  String get zones_orderByName => 'Por pabellón';

  @override
  String get zones_orderMostFree => 'Más espacios libres primero';

  @override
  String get zones_onlyFree => 'Solo pabellones con espacios libres';

  @override
  String get zones_filterReset => 'Restablecer';

  @override
  String get zones_filterDone => 'Listo';

  @override
  String get zones_capacity => 'Capacidad';

  @override
  String get zones_free => 'Libres';

  @override
  String get zones_unknown => 'Sin datos';

  @override
  String get zones_unknownBanner =>
      'Los espacios sin datos no se cuentan como libres hasta que su sensor vuelva a reportar.';

  @override
  String zones_freeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libres',
      one: '$count libre',
    );
    return '$_temp0';
  }

  @override
  String zones_occupiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ocupados',
      one: '$count ocupado',
    );
    return '$_temp0';
  }

  @override
  String zones_unknownCount(int count) {
    return '$count sin datos';
  }

  @override
  String get zones_availabilityGood => 'Buena';

  @override
  String get zones_availabilityLimited => 'Limitada';

  @override
  String get zones_availabilityFull => 'Llena';

  @override
  String get zones_availabilityNoData => 'Sin datos';

  @override
  String zones_zoneSemantics(
    String name,
    String description,
    String free,
    String unknown,
    String availability,
  ) {
    return '$name$description: $free, $unknown, disponibilidad $availability';
  }

  @override
  String get zones_openLevels => 'Abre los niveles del pabellón';

  @override
  String get zones_openLevelMap => 'Abre el mapa del nivel';

  @override
  String get zones_loading => 'Cargando los pabellones…';

  @override
  String get zones_emptyTitle => 'Esta sede aún no tiene pabellones';

  @override
  String get zones_emptyMessage => 'Desliza hacia abajo para revisar otra vez.';

  @override
  String get zones_noFreeTitle => 'Ningún pabellón tiene espacios libres ahora';

  @override
  String get zones_noFreeMessage =>
      'Muéstralos todos para ver qué tan lleno está cada uno.';

  @override
  String get zones_showAll => 'Mostrar todos los pabellones';

  @override
  String get zones_partialLayout =>
      'No pudimos cargar los pabellones. Mostramos los totales de la sede.';

  @override
  String get zones_partialOccupancy =>
      'No pudimos cargar la disponibilidad. Mostramos los pabellones sin conteos.';

  @override
  String get zones_notFoundTitle => 'No encontramos este pabellón';

  @override
  String get zones_levelNotFoundTitle => 'No encontramos este nivel';

  @override
  String get zones_notFoundMessage =>
      'La distribución pudo cambiar. Vuelve a la lista.';

  @override
  String get zones_backToZones => 'Volver a estacionamiento';

  @override
  String get zones_levelsHeading => 'Niveles';

  @override
  String get zones_viewLabel => 'Vista';

  @override
  String get zones_viewMap => 'Mapa';

  @override
  String get zones_viewList => 'Lista';

  @override
  String zones_mapSummary(String free, String occupied, String unknown) {
    return 'Mapa: $free, $occupied, $unknown';
  }

  @override
  String get zones_noMap => 'Este nivel aún no tiene mapa. Mostramos la lista.';

  @override
  String get zones_filterAll => 'Todos';

  @override
  String get zones_filterFree => 'Libres';

  @override
  String get zones_filterUnknown => 'Sin datos';

  @override
  String get zones_listEmpty => 'Ningún espacio coincide con este filtro.';

  @override
  String zones_spaceSemantics(String label, String state) {
    return 'Espacio $label: $state';
  }

  @override
  String get zones_reasonNoHeartbeat => 'Sin señal del sensor';

  @override
  String get zones_reasonLowBattery => 'Batería del sensor baja';

  @override
  String get zones_reasonNoSensor => 'Sin sensor asignado';

  @override
  String get zones_reasonWaiting => 'Esperando datos';

  @override
  String get forecast_etaAction => 'Elegir tu hora de llegada';

  @override
  String get forecast_ifLeaveNow => 'Si sales ahora';

  @override
  String get forecast_yourArrivalTime => 'Tu hora de llegada';

  @override
  String forecast_arriveIn(int minutes) {
    return 'Llegas en $minutes min';
  }

  @override
  String get forecast_etaManual => 'Elegido por ti';

  @override
  String get forecast_etaEstimating => 'Calculando…';

  @override
  String get forecast_etaPrompt => 'Elige cuándo llegas';

  @override
  String get forecast_etaPromptCaption => 'Tu llegada';

  @override
  String forecast_heroSemantics(
    String caption,
    String headline,
    String source,
  ) {
    return '$caption. $headline. $source';
  }

  @override
  String get forecast_yourArrivalTag => 'Tu llegada';

  @override
  String forecast_confidenceLine(String level) {
    return 'Confianza: $level';
  }

  @override
  String get forecast_rowMissing => 'Sin pronóstico para este horizonte';

  @override
  String get forecast_rowExpired => 'Pronóstico vencido';

  @override
  String get forecast_rowNoOdds => 'Probabilidad de llegada no disponible';

  @override
  String get forecast_rowHint => 'Abre el detalle del pronóstico';

  @override
  String forecast_rowSpoken(
    int minutes,
    String time,
    int percent,
    String category,
    String confidence,
    String tag,
  ) {
    return '$minutes min, a las $time: $percent por ciento, $category. $confidence.$tag';
  }

  @override
  String forecast_rowSpokenOther(
    int minutes,
    String time,
    String state,
    String tag,
  ) {
    return '$minutes min, a las $time: $state.$tag';
  }

  @override
  String get forecast_note =>
      'Estimación con ocupación histórica, flujo, calendario académico y eventos.';

  @override
  String forecast_generatedAt(String time, String age) {
    return 'Generada a las $time · $age';
  }

  @override
  String get forecast_partialMissing =>
      'Faltan algunos pronósticos. Mostramos los que hay.';

  @override
  String get forecast_partialExpired =>
      'Algunos pronósticos vencieron y no se muestran como actuales.';

  @override
  String get forecast_partialDetails =>
      'No pudimos cargar el detalle de los pronósticos. Mostramos las probabilidades de llegada.';

  @override
  String get forecast_lowConfidenceBanner =>
      'Hay poco historial de esta sede. Toma estos números como una referencia.';

  @override
  String get forecast_emptyTitle => 'Aún no hay pronósticos';

  @override
  String get forecast_emptyMessage =>
      'Esta sede aún no acumula historial suficiente. Vuelve más tarde.';

  @override
  String get forecast_loading => 'Cargando pronósticos…';

  @override
  String forecast_detailTitle(int minutes) {
    return 'Pronóstico a $minutes min';
  }

  @override
  String get forecast_detailClose => 'Cerrar';

  @override
  String forecast_detailForTime(String time) {
    return 'Para las $time';
  }

  @override
  String get forecast_detailChance => 'Probabilidad de encontrar espacio';

  @override
  String get forecast_detailOccupancy => 'Ocupación esperada';

  @override
  String get forecast_detailSaturation => 'Saturación';

  @override
  String forecast_detailFillsAt(String time, String percent) {
    return 'Se llenaría a las $time ($percent %)';
  }

  @override
  String get forecast_detailNoSaturation => 'No se prevé que se llene';

  @override
  String get forecast_detailGenerated => 'Generada';

  @override
  String get forecast_detailValid => 'Vigente por';

  @override
  String forecast_detailValidMinutes(int minutes) {
    return '$minutes min más';
  }

  @override
  String get forecast_detailValidSoon => 'Menos de un minuto';

  @override
  String get forecast_detailExpired => 'Vencida';

  @override
  String get forecast_detailSource => 'Origen';

  @override
  String get forecast_sourceModel => 'Modelo principal';

  @override
  String get forecast_sourceFallback =>
      'Estimación de contingencia (historial limitado)';

  @override
  String forecast_detailModel(String version) {
    return 'Modelo $version';
  }

  @override
  String get forecast_detailLowConfidence =>
      'Este pronóstico se basa en información limitada. Úsalo como referencia.';

  @override
  String get forecast_detailExpiredNote =>
      'Este pronóstico venció y no se muestra como actual.';

  @override
  String get forecast_detailMissingNote =>
      'Todavía no hay pronóstico para este horizonte.';

  @override
  String get alerts_loading => 'Cargando tus alertas…';

  @override
  String get alerts_errorTitle => 'No pudimos cargar tus alertas';

  @override
  String get alerts_partialPreferences => 'No pudimos cargar tus preferencias.';

  @override
  String get alerts_partialSlots => 'No pudimos cargar tus franjas.';

  @override
  String get alerts_pushTitle => 'Recibir notificaciones';

  @override
  String get alerts_pushOn => 'Te avisaremos en este teléfono.';

  @override
  String get alerts_pushOff =>
      'Desactivadas: no recibirás alertas, ni de las franjas que sigues.';

  @override
  String get alerts_sectionWhen => 'Avísame cuando';

  @override
  String get alerts_whenOffHint =>
      'Activa las notificaciones para elegir qué alertas recibes.';

  @override
  String get alerts_saturationTitle =>
      'Se prevea que se llene el estacionamiento';

  @override
  String get alerts_saturationHelp => 'En las franjas que sigues';

  @override
  String get alerts_lowArrivalTitle => 'La disponibilidad sea baja';

  @override
  String get alerts_lowArrivalHelp => 'Para tu hora estimada de llegada';

  @override
  String get alerts_staleTitle => 'Los datos estén desactualizados';

  @override
  String get alerts_staleHelp => 'Más de 10 minutos sin lectura';

  @override
  String get alerts_eventsTitle => 'Haya cambios por eventos';

  @override
  String get alerts_eventsHelp => 'Solo eventos del calendario del campus';

  @override
  String get alerts_slotsTitle => 'Tus franjas';

  @override
  String get alerts_slotsEmptyTitle => 'Aún no sigues ninguna franja';

  @override
  String get alerts_slotsEmptyMessage =>
      'Elige los días y la hora en que sueles llegar y te avisamos si se prevé que el estacionamiento se llene.';

  @override
  String get alerts_addSlot => 'Agregar franja';

  @override
  String get alerts_slotPaused => 'Pausada';

  @override
  String alerts_slotSwitchLabel(String lot, String days, String time) {
    return 'Alertas de $lot, $days, $time';
  }

  @override
  String alerts_slotDeleteTooltip(String lot, String days, String time) {
    return 'Eliminar la franja de $lot, $days, $time';
  }

  @override
  String get alerts_deleteTitle => '¿Eliminar esta franja?';

  @override
  String alerts_deleteSubject(String lot, String days, String time) {
    return '$lot · $days · $time';
  }

  @override
  String get alerts_deleteMessage =>
      'Dejarás de recibir alertas de esta franja. Tus demás franjas se conservan.';

  @override
  String get alerts_deleteConfirm => 'Eliminar';

  @override
  String get alerts_deleteCancel => 'Cancelar';

  @override
  String get alerts_connectivityTitle => 'Conectividad intermitente';

  @override
  String get alerts_connectivityValue => 'Automático';

  @override
  String get alerts_connectivityHelp =>
      'Conserva la última consulta y sincroniza al recuperar conexión.';

  @override
  String get alerts_privacy =>
      'Tus preferencias quedan en tu cuenta. Quadrapp no recibe tu ubicación; solo minutos de llegada.';

  @override
  String get alerts_noticePermissionDenied =>
      'Sin el permiso de notificaciones no podemos avisarte.';

  @override
  String get alerts_noticePermissionBlocked =>
      'Las notificaciones están bloqueadas. Actívalas en los ajustes del teléfono.';

  @override
  String get alerts_noticeActivationFailed =>
      'No pudimos activar las notificaciones en este teléfono. Inténtalo más tarde.';

  @override
  String get alerts_noticeSaveFailed =>
      'No pudimos guardar tus preferencias. Inténtalo de nuevo.';

  @override
  String get alerts_noticeSlotFailed =>
      'No pudimos actualizar la franja. Inténtalo de nuevo.';

  @override
  String get alerts_noticeSlotDuplicate =>
      'Ya sigues esa franja, así que esta queda pausada.';

  @override
  String get alerts_noticeDeleteFailed =>
      'No pudimos eliminar la franja. Inténtalo de nuevo.';

  @override
  String get alerts_noticeDeleted => 'Franja eliminada';

  @override
  String get alerts_noticeCreated => 'Franja agregada';

  @override
  String get alerts_noticeCreatedDenied =>
      'Franja agregada, pero sin el permiso de notificaciones no podemos avisarte.';

  @override
  String get alerts_noticeCreatedBlocked =>
      'Franja agregada. Las notificaciones están bloqueadas: actívalas en los ajustes del teléfono.';

  @override
  String get alerts_noticeCreatedNoDevice =>
      'Franja agregada, pero no pudimos activar las notificaciones en este teléfono.';

  @override
  String get alerts_sheetTitle => 'Nueva franja';

  @override
  String get alerts_sheetSubtitle =>
      'Te avisaremos si prevemos que se llena en este horario.';

  @override
  String get alerts_sheetClose => 'Cerrar';

  @override
  String get alerts_sheetLot => 'Sede';

  @override
  String get alerts_sheetDays => 'Días';

  @override
  String get alerts_sheetFrom => 'Desde';

  @override
  String get alerts_sheetTo => 'Hasta';

  @override
  String get alerts_sheetPickTime => 'Elegir hora';

  @override
  String get alerts_sheetPermissionHint =>
      'Te pediremos el permiso de notificaciones si aún no lo diste.';

  @override
  String get alerts_sheetCreate => 'Agregar franja';

  @override
  String get alerts_sheetCreating => 'Agregando…';

  @override
  String get alerts_errorDays => 'Elige al menos un día.';

  @override
  String get alerts_errorTimes => 'Elige la hora de inicio y la de fin.';

  @override
  String get alerts_errorOrder =>
      'La hora de fin debe ser posterior a la de inicio.';

  @override
  String get alerts_errorDuplicate => 'Ya sigues esta franja.';

  @override
  String get alerts_errorNoLot => 'Elige una sede.';

  @override
  String get legal_neverBody =>
      'Tu ubicación. Tu tiempo de llegada se calcula en tu teléfono y a Quadrapp solo llegan los minutos. Si activas el tráfico en tiempo real, tu ubicación aproximada (unos 100 m) se envía a Google solo para calcular ese tiempo; Quadrapp no la recibe ni la guarda. No leemos placas y no manejamos pagos.';

  @override
  String get eta_sourceTraffic => 'con tráfico en vivo';

  @override
  String get eta_sourceDevice => 'estimado en tu teléfono';

  @override
  String eta_updatedAgo(String age) {
    return 'Tu llegada se actualizó $age';
  }

  @override
  String get eta_autoTitle => 'Calcular mi llegada automáticamente';

  @override
  String get eta_autoOn =>
      'Estimamos cuánto tardas desde donde estás y lo mantenemos al día.';

  @override
  String get eta_autoOff =>
      'Apagado: no usaremos tu ubicación. Solo vale la hora que elijas abajo.';

  @override
  String get eta_trafficTitle => 'Incluir el tráfico en tiempo real';

  @override
  String get eta_trafficOn =>
      'Tu ubicación aproximada (unos 100 m) se envía a Google para calcular el tráfico, solo para este cálculo. Quadrapp no la recibe ni la guarda.';

  @override
  String get eta_trafficOff =>
      'Apagado: tu ubicación no sale del teléfono. La estimación no incluye el tráfico.';

  @override
  String eta_currentSummary(int minutes, String source) {
    return 'Ahora: $minutes min · $source';
  }

  @override
  String get eta_manualCountdown =>
      'Elegido por ti. Baja solo con el paso del tiempo.';

  @override
  String get eta_backToAuto => 'Volver al automático';

  @override
  String get eta_tooFar =>
      'Estás a más de 2 horas del campus. La asesoría empieza cuando estés más cerca; mientras, puedes elegir una hora.';

  @override
  String get home_statementTooFar =>
      'Estás a más de 2 horas del campus. Te mostramos qué esperar cuando estés más cerca. Mientras, puedes elegir una hora.';

  @override
  String get home_arriveNow => 'Ya llegaste';

  @override
  String get home_privacyLineTraffic =>
      'Quadrapp recibe solo los minutos de llegada. Con el tráfico en vivo activado, tu ubicación aproximada va a Google.';

  @override
  String home_changeEta(int eta, int previous) {
    return 'Actualizado: llegas en $eta min (antes $previous)';
  }

  @override
  String home_changeChance(int percent, int previous) {
    return 'Probabilidad de espacio: $percent % (antes $previous %)';
  }

  @override
  String home_changeCategory(String category, String previous) {
    return 'Ahora: $category (antes: $previous)';
  }

  @override
  String get forecast_etaTraffic => 'Con tráfico en vivo';

  @override
  String get forecast_etaDevice => 'Estimado en tu teléfono';

  @override
  String get forecast_tooFar => 'A más de 2 horas';

  @override
  String get debug_simulateTrip => 'Simular el viaje al campus';

  @override
  String get debug_simulateTripHelp =>
      'El teléfono simulado va al campus elegido a 150 km/h: el tiempo de llegada baja solo y la asesoría se actualiza.';

  @override
  String get debug_heavyTraffic => 'Tráfico pesado';

  @override
  String get debug_heavyTrafficHelp =>
      'El proveedor de mapas simulado multiplica el viaje por 1,8 en lugar de 1,3.';

  @override
  String get debug_routesOutage => 'Proveedor de mapas caído';

  @override
  String get debug_routesOutageHelp =>
      'La app usa la estimación del teléfono, sin mostrar un error.';

  @override
  String get eta_updatedNow => 'Tu llegada se acaba de actualizar';
}
