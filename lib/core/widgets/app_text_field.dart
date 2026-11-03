import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_tokens.dart';
import '../theme/app_type.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscure = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.keyboardType,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;
  final int? minLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppType.label.copyWith(color: t.textMuted)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _hidden,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          keyboardType: widget.maxLines > 1 ? TextInputType.multiline : widget.keyboardType,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.obscure ? null : widget.minLines,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          style: AppType.body.copyWith(color: t.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppType.body.copyWith(color: t.textFaint),
            filled: true,
            fillColor: t.surfaceRaised,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 19, color: t.textMuted),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? s.showPassword : s.hidePassword,
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 19,
                      color: t.textMuted,
                    ),
                  )
                : null,
            enabledBorder: border(t.border),
            disabledBorder: border(t.border),
            focusedBorder: border(t.accent, 1.5),
            errorBorder: border(t.danger),
            focusedErrorBorder: border(t.danger, 1.5),
            errorStyle: AppType.caption.copyWith(color: t.danger),
          ),
        ),
      ],
    );
  }
}
