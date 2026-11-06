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
  final TextEditingController _email = TextEditingController(
    text: 'engineer@fieldpulse.dev',
  );
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      FocusScope.of(context).unfocus();
      await getIt<AuthCubit>().signIn(
        email: _email.text,
        password: _password.text,
      );
    }
  }

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _PageShell(child: _LoginSection(data: _data())),
    );
  }

  _LoginFormData _data() {
    return _LoginFormData(
      formKey: _formKey,
      email: _email,
      password: _password,
      obscure: _obscure,
      onSubmit: _submit,
      onToggle: _toggleObscure,
    );
  }
}

class _LoginFormData {
  const _LoginFormData({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.onSubmit,
    required this.onToggle,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final Future<void> Function() onSubmit;
  final VoidCallback onToggle;
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: _MaxWidth(child: child)),
    );
  }
}

class _MaxWidth extends StatelessWidget {
  const _MaxWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: child,
      ),
    );
  }
}

class _LoginSection extends StatelessWidget {
  const _LoginSection({required this.data});

  final _LoginFormData data;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: _hasNewError,
      listener: _showError,
      builder: _builder,
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

  Widget _builder(BuildContext context, AuthState state) {
    return _LoginForm(data: data, state: state);
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.data, required this.state});

  final _LoginFormData data;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: data.formKey,
      child: _FormColumn(data: data, state: state),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.data, required this.state});

  final _LoginFormData data;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _parts(),
    );
  }

  List<Widget> _parts() {
    return [
      const _BrandHeader(),
      const SizedBox(height: 32),
      _EmailField(
        controller: data.email,
        errorText: state.fieldErrors['email'],
      ),
      const SizedBox(height: 16),
      _PasswordField(
        controller: data.password,
        errorText: state.fieldErrors['password'],
        obscure: data.obscure,
        onToggle: data.onToggle,
        onSubmit: data.onSubmit,
      ),
      const SizedBox(height: 24),
      _SubmitButton(isLoading: state.isSubmitting, onPressed: data.onSubmit),
      const SizedBox(height: 16),
      const _BiometricHint(),
    ];
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: _parts(theme));
  }

  List<Widget> _parts(ThemeData theme) {
    return [
      Icon(Icons.bolt_rounded, size: 56, color: theme.colorScheme.primary),
      const SizedBox(height: 16),
      Text(
        'FieldPulse',
        textAlign: TextAlign.center,
        style: _titleStyle(theme),
      ),
      const SizedBox(height: 8),
      Text(
        'Наряды, статусы и фотоотчёты — офлайн и в реальном времени',
        textAlign: TextAlign.center,
        style: _subtitleStyle(theme),
      ),
    ];
  }

  TextStyle? _titleStyle(ThemeData theme) =>
      theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? _subtitleStyle(ThemeData theme) => theme.textTheme.bodyMedium
      ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
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
      decoration: _decoration(),
      validator: _validate,
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      labelText: 'Рабочая почта',
      errorText: errorText,
      prefixIcon: const Icon(Icons.mail_outline),
    );
  }

  String? _validate(String? value) {
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
      decoration: _decoration(),
      validator: _validate,
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      labelText: 'Пароль',
      errorText: errorText,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: _toggleButton(),
    );
  }

  Widget _toggleButton() {
    return IconButton(
      tooltip: obscure ? 'Показать' : 'Скрыть',
      onPressed: onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }

  String? _validate(String? value) =>
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
    return context.isCupertinoPlatform ? _hint() : const SizedBox.shrink();
  }

  Widget _hint() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'На iOS вход защищён Face ID / Touch ID',
        textAlign: TextAlign.center,
      ),
    );
  }
}
