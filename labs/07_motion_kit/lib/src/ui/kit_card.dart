import 'package:flutter/material.dart';

class CardShell extends StatelessWidget {
  const CardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: _CardPadding(child: child));
  }
}

class _CardPadding extends StatelessWidget {
  const _CardPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: child);
  }
}

class KitCard extends StatelessWidget {
  const KitCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: _TitledBody(title: title, child: child),
    );
  }
}

class _TitledBody extends StatelessWidget {
  const _TitledBody({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parts(context),
    );
  }

  List<Widget> _parts(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Text(title, style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      child,
    ];
  }
}

class CaptionText extends StatelessWidget {
  const CaptionText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style ?? Theme.of(context).textTheme.bodyMedium);
  }
}
