import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// TextField que toca sons de digitação
class SoundTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLength;
  final bool playSounds;
  final TextCapitalization textCapitalization;

  const SoundTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.decoration,
    this.style,
    this.maxLength,
    this.playSounds = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<SoundTextField> createState() => _SoundTextFieldState();
}

class _SoundTextFieldState extends State<SoundTextField> {
  late TextEditingController _controller;
  bool _isControllerInternal = false;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _isControllerInternal = widget.controller == null;
    _previousLength = _controller.text.length;
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SoundTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_isControllerInternal) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _isControllerInternal = widget.controller == null;
      _previousLength = _controller.text.length;
      _controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (!widget.playSounds) return;

    final currentLength = _controller.text.length;
    
    if (currentLength > _previousLength) {
      // Texto adicionado - som de digitação
      soundService.playSndType();
    } else if (currentLength < _previousLength) {
      // Texto deletado - som de delete (mais suave)
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }
    
    _previousLength = currentLength;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
          ),
    );
  }
}

/// TextFormField que toca sons de digitação
class SoundTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLength;
  final bool playSounds;
  final TextCapitalization textCapitalization;
  final void Function(String?)? onSaved;
  final AutovalidateMode? autovalidateMode;

  const SoundTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.decoration,
    this.style,
    this.maxLength,
    this.playSounds = true,
    this.textCapitalization = TextCapitalization.none,
    this.onSaved,
    this.autovalidateMode,
  });

  @override
  State<SoundTextFormField> createState() => _SoundTextFormFieldState();
}

class _SoundTextFormFieldState extends State<SoundTextFormField> {
  late TextEditingController _controller;
  bool _isControllerInternal = false;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _isControllerInternal = widget.controller == null;
    _previousLength = _controller.text.length;
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SoundTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_isControllerInternal) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _isControllerInternal = widget.controller == null;
      _previousLength = _controller.text.length;
      _controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (!widget.playSounds) return;

    final currentLength = _controller.text.length;
    
    if (currentLength > _previousLength) {
      // Texto adicionado - som de digitação
      soundService.playSndType();
    } else if (currentLength < _previousLength) {
      // Texto deletado - som de delete (mais suave)
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }
    
    _previousLength = currentLength;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      style: widget.style,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
          ),
    );
  }
}
