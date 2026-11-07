import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_parts.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Botones, campos, OTP, selector de franja y diálogo.
class GalleryInputs extends StatefulWidget {
  const GalleryInputs({super.key});

  @override
  State<GalleryInputs> createState() => _GalleryInputsState();
}

class _GalleryInputsState extends State<GalleryInputs> {
  final _email = TextEditingController(text: 'ana@upc.edu.pe');
  final _otpPartial = TextEditingController(text: '123');
  final _otpError = TextEditingController(text: '123456');
  Set<int> _days = {1, 2, 3, 4, 5};
  TimeOfDay? _from = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay? _to = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _email.dispose();
    _otpPartial.dispose();
    _otpError.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final symbols = DateFormat.E(locale).dateSymbols;
    List<String> mondayFirst(List<String> sundayFirst) => [
      ...sundayFirst.sublist(1),
      sundayFirst.first,
    ];

    Widget buttons({
      bool loading = false,
      bool disabled = false,
    }) => Wrap(
      spacing: QaSpacing.md,
      runSpacing: QaSpacing.md,
      children: [
        QaButton(
          label: l10n.gallery_buttonPrimary,
          loadingLabel: l10n.gallery_stateLoading,
          isLoading: loading,
          onPressed: disabled ? null : () {},
        ),
        QaButton(
          label: l10n.gallery_buttonTonal,
          loadingLabel: l10n.gallery_stateLoading,
          variant: QaButtonVariant.tonal,
          isLoading: loading,
          onPressed: disabled ? null : () {},
        ),
        QaButton(
          label: l10n.gallery_buttonText,
          loadingLabel: l10n.gallery_stateLoading,
          variant: QaButtonVariant.text,
          isLoading: loading,
          onPressed: disabled ? null : () {},
        ),
        QaButton(
          label: l10n.gallery_buttonDestructive,
          loadingLabel: l10n.gallery_stateLoading,
          variant: QaButtonVariant.destructive,
          isLoading: loading,
          onPressed: disabled ? null : () {},
        ),
      ],
    );

    Widget slotPicker({
      Set<int>? days,
      TimeOfDay? from,
      TimeOfDay? to,
      ValueChanged<Set<int>>? onDays,
      ValueChanged<TimeOfDay>? onFrom,
      ValueChanged<TimeOfDay>? onTo,
      String? error,
      bool enabled = true,
    }) => QaTimeSlotPicker(
      dayLabels: mondayFirst(symbols.SHORTWEEKDAYS),
      dayNames: mondayFirst(symbols.WEEKDAYS),
      selectedDays: days ?? const {},
      from: from,
      to: to,
      daysLabel: l10n.gallery_slotDays,
      fromLabel: l10n.gallery_slotFrom,
      toLabel: l10n.gallery_slotTo,
      pickTimeLabel: l10n.gallery_slotPick,
      onDaysChanged: onDays ?? (_) {},
      onFromChanged: onFrom ?? (_) {},
      onToChanged: onTo ?? (_) {},
      errorText: error,
      enabled: enabled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GallerySection(
          title: 'QaButton',
          children: [
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: buttons(),
            ),
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: buttons(loading: true),
            ),
            GalleryState(
              label: l10n.gallery_stateDisabled,
              child: buttons(disabled: true),
            ),
          ],
        ),
        GallerySection(
          title: 'QaTextField',
          children: [
            GalleryState(
              label: l10n.gallery_stateEmpty,
              child: QaTextField(
                label: l10n.gallery_fieldLabel,
                hint: l10n.gallery_fieldHint,
                helperText: l10n.gallery_fieldHelper,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateFilled,
              child: QaTextField(
                label: l10n.gallery_fieldLabel,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateError,
              child: QaTextField(
                label: l10n.gallery_fieldLabel,
                errorText: l10n.gallery_fieldError,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateDisabled,
              child: QaTextField(
                label: l10n.gallery_fieldLabel,
                enabled: false,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaOtpField',
          children: [
            GalleryState(
              label: l10n.gallery_stateEmpty,
              child: QaOtpField(semanticLabel: l10n.gallery_otpLabel),
            ),
            GalleryState(
              label: l10n.gallery_stateFilled,
              child: QaOtpField(
                semanticLabel: l10n.gallery_otpLabel,
                controller: _otpPartial,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateError,
              child: QaOtpField(
                semanticLabel: l10n.gallery_otpLabel,
                controller: _otpError,
                errorText: l10n.gallery_otpError,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateDisabled,
              child: QaOtpField(
                semanticLabel: l10n.gallery_otpLabel,
                enabled: false,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaTimeSlotPicker',
          children: [
            GalleryState(
              label: l10n.gallery_stateEmpty,
              child: slotPicker(),
            ),
            GalleryState(
              label: l10n.gallery_stateFilled,
              child: slotPicker(
                days: _days,
                from: _from,
                to: _to,
                onDays: (days) => setState(() => _days = days),
                onFrom: (time) => setState(() => _from = time),
                onTo: (time) => setState(() => _to = time),
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateError,
              child: slotPicker(
                days: const {1, 3},
                from: const TimeOfDay(hour: 9, minute: 0),
                to: const TimeOfDay(hour: 7, minute: 30),
                error: l10n.gallery_slotError,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateDisabled,
              child: slotPicker(
                days: const {1, 2},
                from: const TimeOfDay(hour: 7, minute: 30),
                to: const TimeOfDay(hour: 9, minute: 0),
                enabled: false,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaDialog',
          children: [
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: Wrap(
                spacing: QaSpacing.md,
                runSpacing: QaSpacing.md,
                children: [
                  QaButton(
                    label: l10n.gallery_dialogOpen,
                    variant: QaButtonVariant.tonal,
                    onPressed: () => showQaDialog(
                      context,
                      title: l10n.gallery_dialogTitle,
                      message: l10n.gallery_dialogMessage,
                      confirmLabel: l10n.gallery_dialogConfirm,
                      cancelLabel: l10n.gallery_dialogCancel,
                    ),
                  ),
                  QaButton(
                    label: l10n.gallery_dialogTitle,
                    variant: QaButtonVariant.destructive,
                    onPressed: () => showQaDialog(
                      context,
                      title: l10n.gallery_dialogTitle,
                      message: l10n.gallery_dialogMessage,
                      confirmLabel: l10n.gallery_dialogConfirm,
                      cancelLabel: l10n.gallery_dialogCancel,
                      destructive: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
