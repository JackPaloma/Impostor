import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'lobby_colors.dart';

// 1. EL ENCABEZADO (TÍTULO Y AJUSTES SIN IMÁGENES)
class LobbyHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const LobbyHeader({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        const Text(
            "IMPOSTOR",
            style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 4.0,
                color: lobbyGold,
                shadows: [Shadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 8)]
            )
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.gear, color: lobbyGold, size: 26),
              onPressed: onSettingsTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

// 2. LAS TARJETAS OSCURAS PREMIUM
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: color ?? ebonyCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor ?? lobbyGoldDark.withOpacity(0.5), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 8))]
      ),
      child: child,
    );
  }
}

// 3. EL BOTÓN GIGANTE DE INICIAR PARTIDA
class StartGameButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const StartGameButton({super.key, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isActive ? lobbyGold : ebonyInput,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: goldDark),
          boxShadow: isActive ? const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6))] : [],
        ),
        child: Center(
          child: Text(
              "INICIAR PARTIDA",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isActive ? const Color(0xFF2A1B0E) : textMuted
              )
          ),
        ),
      ),
    );
  }
}

// 4. CAJA DE TEXTO PERSONALIZADA PARA DIÁLOGOS
class GoldInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const GoldInput({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: textMain, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted),
        filled: true,
        fillColor: ebonyInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lobbyGold, width: 1.5)),
      ),
    );
  }
}

// 5. SWITCHES PERSONALIZADOS PARA LAS REGLAS
class GoldSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final Function(bool) onChanged;

  const GoldSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: Text(title, style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: textMuted, fontWeight: FontWeight.w500, fontSize: 12)),
        value: value,
        activeColor: color,
        activeTrackColor: color.withOpacity(0.3),
        inactiveThumbColor: textMuted,
        inactiveTrackColor: ebonyInput,
        onChanged: onChanged
    );
  }
}