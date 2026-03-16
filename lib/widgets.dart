import 'package:flutter/material.dart';
import 'theme.dart';
import '../audio.dart';

Color _getShadowColor(Color color) {
  final HSLColor hsl = HSLColor.fromColor(color);
  final HSLColor hslDark = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
  return hslDark.toColor();
}

class DuoButton extends StatefulWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Color color;
  final Color? shadowColor;
  final IconData? icon;

  const DuoButton({
    super.key,
    this.text,
    required this.onPressed,
    this.color = duoBlue,
    this.shadowColor,
    this.icon,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color mainColor = widget.onPressed == null
        ? duoBorder
        : (widget.color == duoSurface ? duoSurface : widget.color);

    Color shadow;
    if (widget.onPressed == null) {
      shadow = const Color(0xFF2A3A44);
    } else if (widget.color == duoSurface) {
      shadow = duoBorder;
    } else {
      shadow = widget.shadowColor ?? _getShadowColor(mainColor);
    }

    Color contentColor;
    if (widget.onPressed == null) {
      contentColor = duoTextSub;
    } else if (widget.color == duoSurface) {
      contentColor = AppTheme.primary;
    } else {
      contentColor = Colors.white;
    }

    if (widget.color == const Color(0xFFF5F0E1) || widget.color == const Color(0xFFE3CA94)) {
      contentColor = duoBg;
      shadow = duoBorder;
    }

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          Sonidos.playClick();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0, bottom: _isPressed ? 0 : 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: contentColor, size: 24),
              if (widget.text != null) const SizedBox(width: 10)
            ],
            if (widget.text != null)
              Flexible(
                child: Text(
                  widget.text!.toUpperCase(),
                  style: duoFont(size: 16, color: contentColor),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DuoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onSubmitted;

  const DuoInput({
    super.key,
    required this.controller,
    required this.hint,
    this.onSubmitted
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: duoSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: duoBorder, width: 2),
      ),
      child: TextField(
        controller: controller,
        style: duoFont(size: 18, color: duoTextMain),
        onSubmitted: onSubmitted,
        cursorColor: AppTheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: duoTextSub, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class DuoFondo extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;
  final bool opacity;
  final String imagen; // <--- NUEVO PARÁMETRO

  const DuoFondo({
    super.key,
    required this.child,
    this.overlayColor,
    this.opacity = true,
    this.imagen = "assets/fondo.png", // <--- VALOR POR DEFECTO
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagen, // <--- USAMOS LA VARIABLE
            fit: BoxFit.cover,
            errorBuilder: (c, o, s) => Container(color: duoBg),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: overlayColor ?? const Color(0xFF131F24).withOpacity(0.40),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}