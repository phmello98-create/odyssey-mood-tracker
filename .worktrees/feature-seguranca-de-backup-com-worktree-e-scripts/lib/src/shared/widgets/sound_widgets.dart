import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';

/// Widgets com sons SND integrados - Inspirado em https://snd.dev
/// 
/// Uso:
/// ```dart
/// SoundButton(
///   onPressed: () => print('clicked'),
///   child: Text('Button'),
/// )
/// ```

// ==========================================
// BUTTON COM SOM
// ==========================================

/// Botão com som SND integrado
class SoundButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const SoundButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: enabled && onPressed != null
          ? () {
              soundService.playSndButton();
              onPressed!();
            }
          : () {
              soundService.playSndDisabled();
            },
      child: child,
    );
  }
}

/// FilledButton com som SND
class SoundFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const SoundFilledButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: style,
      onPressed: enabled && onPressed != null
          ? () {
              soundService.playSndButton();
              onPressed!();
            }
          : () {
              soundService.playSndDisabled();
            },
      child: child,
    );
  }
}

/// TextButton com som SND tap
class SoundTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const SoundTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: onPressed != null
          ? () {
              soundService.playSndTap();
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// IconButton com som SND tap
class SoundIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final ButtonStyle? style;
  final String? tooltip;

  const SoundIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.style,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: style,
      tooltip: tooltip,
      onPressed: onPressed != null
          ? () {
              soundService.playSndTap();
              onPressed!();
            }
          : null,
      icon: icon,
    );
  }
}

// ==========================================
// CARD/LIST TILE COM SOM TAP
// ==========================================

/// Card clicável com som SND tap
class SoundCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;

  const SoundCard({
    Key? key,
    this.onTap,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      color: color,
      elevation: elevation,
      child: InkWell(
        onTap: onTap != null
            ? () {
                soundService.playSndTap();
                onTap!();
              }
            : null,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// ListTile com som SND tap
class SoundListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  const SoundListTile({
    Key? key,
    this.onTap,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap != null
          ? () {
              soundService.playSndTap();
              onTap!();
            }
          : null,
    );
  }
}

// ==========================================
// CHECKBOX COM SOM SELECT
// ==========================================

/// Checkbox com som SND select
class SoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const SoundCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged != null
          ? (val) {
              soundService.playSndSelect();
              onChanged!(val);
            }
          : null,
    );
  }
}

/// CheckboxListTile com som SND select
class SoundCheckboxListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  const SoundCheckboxListTile({
    Key? key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged != null
          ? (val) {
              soundService.playSndSelect();
              onChanged!(val);
            }
          : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
    );
  }
}

// ==========================================
// SWITCH/TOGGLE COM SOM ON/OFF
// ==========================================

/// Switch com som SND toggle on/off
class SoundSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SoundSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged != null
          ? (val) {
              if (val) {
                soundService.playSndToggleOn();
              } else {
                soundService.playSndToggleOff();
              }
              onChanged!(val);
            }
          : null,
    );
  }
}

/// SwitchListTile com som SND toggle on/off
class SoundSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  const SoundSwitchListTile({
    Key? key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged != null
          ? (val) {
              if (val) {
                soundService.playSndToggleOn();
              } else {
                soundService.playSndToggleOff();
              }
              onChanged!(val);
            }
          : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
    );
  }
}

// ==========================================
// RADIO COM SOM SELECT
// ==========================================

/// Radio com som SND select
class SoundRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;

  const SoundRadio({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged != null
          ? (val) {
              soundService.playSndSelect();
              onChanged!(val);
            }
          : null,
    );
  }
}

/// RadioListTile com som SND select
class SoundRadioListTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  const SoundRadioListTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged != null
          ? (val) {
              soundService.playSndSelect();
              onChanged!(val);
            }
          : null,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
    );
  }
}

// ==========================================
// TEXTFIELD COM SOM TYPE
// ==========================================

/// TextField com som SND type (5 variações aleatórias)
/// 
/// Inspirado em snd.dev - toca um som type diferente a cada tecla
/// digitada para evitar fadiga auditiva. Funciona tanto ao digitar
/// quanto ao deletar caracteres (backspace).
class SoundTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final InputDecoration? decoration;
  final bool enabled;
  final FocusNode? focusNode;

  const SoundTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.decoration,
    this.enabled = true,
    this.focusNode,
  }) : super(key: key);

  @override
  State<SoundTextField> createState() => _SoundTextFieldState();
}

class _SoundTextFieldState extends State<SoundTextField> {
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.controller?.text.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
      onChanged: (value) {
        // Toca som type a cada alteração (digitar ou deletar)
        // Usa uma das 5 variações aleatórias (type_01 a type_05)
        // para evitar fadiga auditiva
        if (value.length != _lastLength) {
          soundService.playSndType();
        }
        _lastLength = value.length;
        widget.onChanged?.call(value);
      },
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// TextFormField com som SND type (5 variações aleatórias)
/// 
/// Versão com validação para uso em formulários.
class SoundTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;
  final bool enabled;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  const SoundTextFormField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.validator,
    this.decoration,
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<SoundTextFormField> createState() => _SoundTextFormFieldState();
}

class _SoundTextFormFieldState extends State<SoundTextFormField> {
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.controller?.text.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
      onChanged: (value) {
        // Toca som type a cada alteração (digitar ou deletar)
        // Usa uma das 5 variações aleatórias para evitar fadiga auditiva
        if (value.length != _lastLength) {
          soundService.playSndType();
        }
        _lastLength = value.length;
        widget.onChanged?.call(value);
      },
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}

// ==========================================
// FLOATING ACTION BUTTON COM SOM
// ==========================================

/// FloatingActionButton com som SND button
class SoundFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;

  const SoundFAB({
    Key? key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      onPressed: onPressed != null
          ? () {
              soundService.playSndButton();
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

// ==========================================
// SLIDER COM SOM TAP (início e fim)
// ==========================================

/// Slider com som SND tap no início e fim
class SoundSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  const SoundSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
      onChangeStart: (_) {
        soundService.playSndTap();
      },
      onChangeEnd: (val) {
        soundService.playSndTap();
        onChangeEnd?.call(val);
      },
    );
  }
}

// ==========================================
// CHIP COM SOM SELECT
// ==========================================

/// ChoiceChip com som SND select
class SoundChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const SoundChoiceChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected != null
          ? (val) {
              soundService.playSndSelect();
              onSelected!(val);
            }
          : null,
    );
  }
}

/// FilterChip com som SND select
class SoundFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const SoundFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected != null
          ? (val) {
              soundService.playSndSelect();
              onSelected!(val);
            }
          : null,
    );
  }
}
