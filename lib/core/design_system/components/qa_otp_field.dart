import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Campo de código de un solo uso: 6 casillas sobre un único campo de texto.
///
/// - Acepta el código completo pegado (se filtran los dígitos y se recorta).
/// - `AutofillHints.oneTimeCode` para el autocompletado del SMS o del correo.
/// - Una pulsación larga sobre las casillas pega el portapapeles; no es la
///   única vía (el teclado también sugiere el código).
/// - Expone un único nodo semántico ([semanticLabel]) en lugar de 6 casillas.
/// - Cada casilla mide 48×56 dp con 8 dp entre ellas; si el ancho no alcanza
///   (a 360 dp quedan 312 dp de formulario) se achican por igual a
///   `(ancho − 40) / 6`. El campo entero es un solo objetivo táctil de 56 dp
///   de alto.
class QaOtpField extends StatefulWidget {
  const QaOtpField({
    required this.semanticLabel,
    this.length = 6,
    this.controller,
    this.errorText,
    this.isError = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
    super.key,
  });

  /// Ancho de una casilla cuando hay espacio, y alto de todas.
  static const double cellWidth = 48;
  static const double cellHeight = 56;

  final String semanticLabel;
  final int length;
  final TextEditingController? controller;
  final String? errorText;

  /// Pinta las casillas como erróneas **sin** texto propio: para cuando el
  /// mensaje se muestra en otro lugar (un `QaBanner` con foco).
  final bool isError;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<QaOtpField> createState() => _QaOtpFieldState();
}

class _QaOtpFieldState extends State<QaOtpField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _lastText = _controller.text;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTextChanged() {
    final text = _controller.text;
    if (text == _lastText) {
      // Solo cambió la selección o el cursor.
      setState(() {});
      return;
    }
    _lastText = text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final code = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final text = _controller.text;
    final hasError = widget.errorText != null || widget.isError;
    final activeIndex = text.length.clamp(0, widget.length - 1);

    Widget cell(int index, double width) {
      final isActive = _focusNode.hasFocus && index == activeIndex;
      final borderColor = !widget.enabled
          ? colors.paint
          : hasError
          ? colors.full
          : isActive || index < text.length
          ? colors.primary
          : colors.outline;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: QaRadii.controlRadius,
          border: Border.all(
            color: borderColor,
            width: isActive || hasError ? 2 : 1.5,
          ),
        ),
        child: SizedBox(
          width: width,
          height: QaOtpField.cellHeight,
          child: Center(
            child: Text(
              index < text.length ? text[index] : '',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: widget.enabled
                    ? colors.onSurface
                    : colors.onSurfaceMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutofillGroup(
          child: Semantics(
            label: widget.semanticLabel,
            textField: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // El campo real ignora los toques (IgnorePointer): este detector
              // enfoca al tocar y pega el portapapeles al mantener presionado.
              onTap: widget.enabled ? _focusNode.requestFocus : null,
              onLongPress: widget.enabled ? _pasteFromClipboard : null,
              child: Stack(
                children: [
                  ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gaps = (widget.length - 1) * QaSpacing.sm;
                        final width = constraints.maxWidth.isFinite
                            ? ((constraints.maxWidth - gaps) / widget.length)
                                  .clamp(0.0, QaOtpField.cellWidth)
                            : QaOtpField.cellWidth;
                        return Row(
                          children: [
                            for (var i = 0; i < widget.length; i++) ...[
                              if (i > 0) const SizedBox(width: QaSpacing.sm),
                              cell(i, width),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  // Campo real, transparente, encima de las casillas.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        autofocus: widget.autofocus,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        showCursor: false,
                        enableInteractiveSelection: false,
                        maxLength: widget.length,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(widget.length),
                        ],
                        style: const TextStyle(color: Colors.transparent),
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          filled: false,
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: QaSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colors.full,
                    ),
                  ),
                ),
                const SizedBox(width: QaSpacing.sm),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.full,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
