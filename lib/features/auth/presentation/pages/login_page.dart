import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core_ui/core_ui.dart';
import 'package:fieldpulse/app/di/injector.dart';
import 'package:fieldpulse/features/auth/presentation/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: 'engineer@fieldpulse.dev',
  );
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      FocusScope.of(context).unfocus();
      await getIt<AuthCubit>().signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: BlocConsumer<AuthCubit, AuthState>(
                listenWhen: _hasNewError,
                listener: _showError,
                builder: (context, state) => Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: 32),
                      _EmailField(
                        controller: _emailController,
                        errorText: state.fieldErrors['email'],
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _passwordController,
                        errorText: state.fieldErrors['password'],
                        obscure: _obscure,
                        onToggle: _toggleObscure,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 24),
                      _SubmitButton(
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      const _BiometricHint(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasNewError(AuthState previous, AuthState current) =>
      previous.error != current.error && current.error != null;

  void _showError(BuildContext context, AuthState state) {
    final error = state.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(Icons.bolt_rounded, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'FieldPulse',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Наряды, статусы и фотоотчёты — офлайн и в реальном времени',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Рабочая почта',
        errorText: errorText,
        prefixIcon: const Icon(Icons.mail_outline),
      ),
      validator: _validateEmail,
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return email.contains('@') ? null : 'Укажите почту';
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
    this.errorText,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final Future<void> Function() onSubmit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: 'Пароль',
        errorText: errorText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? 'Показать' : 'Скрыть',
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: _validatePassword,
    );
  }

  String? _validatePassword(String? value) =>
      (value ?? '').length < 6 ? 'Минимум 6 символов' : null;
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? const _ButtonSpinner() : const Text('Войти'),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
    );
  }
}

class _BiometricHint extends StatelessWidget {
  const _BiometricHint();

  @override
  Widget build(BuildContext context) {
    if (!context.isCupertinoPlatform) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'На iOS вход защищён Face ID / Touch ID',
        textAlign: TextAlign.center,
      ),
    );
  }
}
