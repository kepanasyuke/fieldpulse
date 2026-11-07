import 'package:flutter/material.dart';

import 'package:lab_auth_biometrics/src/auth_gate.dart';

void main() => runApp(const AuthLabApp());

class AuthLabApp extends StatelessWidget {
  const AuthLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 09 · Auth & biometrics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthGate _gate = AuthGate(pin: '2468');
  final TextEditingController _input = TextEditingController();

  AuthOutcome? _outcome;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _outcome = _gate.submit(_input.text));
    _input.clear();
  }

  void _reset() {
    setState(() {
      _gate.reset();
      _outcome = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в приложение')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: _sections(context),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    return [
      _StatusCard(gate: _gate, outcome: _outcome),
      const SizedBox(height: 16),
      _PinField(
        controller: _input,
        enabled: !_gate.isLocked,
        onSubmit: _submit,
      ),
      const SizedBox(height: 12),
      _Actions(gate: _gate, onSubmit: _submit, onReset: _reset),
    ];
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.gate, required this.outcome});

  final AuthGate gate;
  final AuthOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = gate.isUnlocked;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unlocked ? 'Доступ открыт' : pinHint(gate.attemptsLeft),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              outcome?.message ?? 'Введите PIN из четырёх цифр',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      onSubmitted: (_) => onSubmit(),
      decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.gate,
    required this.onSubmit,
    required this.onReset,
  });

  final AuthGate gate;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: gate.isLocked || gate.isUnlocked ? null : onSubmit,
            child: const Text('Войти'),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: onReset, child: const Text('Сбросить')),
      ],
    );
  }
}
