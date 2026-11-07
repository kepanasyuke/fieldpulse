import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Палитра и детали оформления в духе оконных менеджеров конца 90-х.
class RetroColors {
  const RetroColors._();

  static const Color desktop = Color(0xFF008080);
  static const Color face = Color(0xFFC0C0C0);
  static const Color light = Color(0xFFFFFFFF);
  static const Color mid = Color(0xFF808080);
  static const Color dark = Color(0xFF404040);
  static const Color titleBar = Color(0xFF000080);
  static const Color titleText = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
}

ThemeData retroTheme() {
  return ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: RetroColors.desktop,
    textTheme: _textTheme(),
    iconTheme: const IconThemeData(color: RetroColors.text, size: 16),
    dividerColor: RetroColors.mid,
  );
}

TextTheme _textTheme() {
  return const TextTheme(
    titleMedium: TextStyle(color: RetroColors.text, fontSize: 15),
    bodyMedium: TextStyle(color: RetroColors.text, fontSize: 14),
    bodySmall: TextStyle(color: RetroColors.text, fontSize: 12),
    labelLarge: TextStyle(color: RetroColors.text, fontSize: 13),
    labelSmall: TextStyle(color: RetroColors.text, fontSize: 11),
    headlineSmall: TextStyle(color: RetroColors.text, fontSize: 20),
  );
}

BoxDecoration retroBevel({bool inset = false}) {
  final topLeft = inset ? RetroColors.mid : RetroColors.light;
  final bottomRight = inset ? RetroColors.light : RetroColors.dark;

  return BoxDecoration(
    color: RetroColors.face,
    border: Border(
      top: BorderSide(color: topLeft, width: 2),
      left: BorderSide(color: topLeft, width: 2),
      right: BorderSide(color: bottomRight, width: 2),
      bottom: BorderSide(color: bottomRight, width: 2),
    ),
  );
}

class RetroIcon extends StatelessWidget {
  const RetroIcon(this.asset, {super.key, this.size = 16});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$asset',
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }
}

class RetroWindow extends StatelessWidget {
  const RetroWindow({
    super.key,
    required this.title,
    required this.child,
    this.icon = 'monitor.svg',
  });

  final String title;
  final Widget child;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: retroBevel(),
      padding: const EdgeInsets.all(3),
      child: Column(mainAxisSize: MainAxisSize.min, children: _parts()),
    );
  }

  List<Widget> _parts() {
    return [_TitleBar(title: title, icon: icon), child];
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, required this.icon});

  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RetroColors.titleBar,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: _items(context)),
    );
  }

  List<Widget> _items(BuildContext context) {
    return [
      RetroIcon(icon),
      const SizedBox(width: 6),
      Expanded(child: _title(context)),
      const _WindowButton(label: '–'),
      const SizedBox(width: 2),
      const _WindowButton(label: '□'),
      const SizedBox(width: 2),
      const _WindowButton(label: '✕'),
    ];
  }

  Widget _title(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: RetroColors.titleText);

    return Text(title, style: style, overflow: TextOverflow.ellipsis);
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 16,
      alignment: Alignment.center,
      decoration: retroBevel(),
      child: Text(label, style: const TextStyle(fontSize: 10, height: 1)),
    );
  }
}

class RetroPanel extends StatelessWidget {
  const RetroPanel({super.key, required this.child, this.padding = 12});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: retroBevel(inset: true),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class RetroButton extends StatelessWidget {
  const RetroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final String? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final face = selected ? RetroColors.mid : RetroColors.face;

    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: retroBevel(inset: selected).copyWith(color: face),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: _items(context)),
      ),
    );
  }

  List<Widget> _items(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;

    return [
      if (icon != null) ...[
        SvgPicture.asset('assets/icons/$icon', width: 14, height: 14),
        const SizedBox(width: 5),
      ],
      Text(label, style: style),
    ];
  }
}
