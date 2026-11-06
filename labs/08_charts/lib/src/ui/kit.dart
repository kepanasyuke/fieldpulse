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

class TitledCard extends StatelessWidget {
  const TitledCard({super.key, required this.title, required this.child});

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

class ValueLine extends StatelessWidget {
  const ValueLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _ValueText(label: label, value: value),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
