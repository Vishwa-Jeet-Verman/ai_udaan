import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController =
      TextEditingController(); // Changed from _emailController
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _useEmail = true; // Toggle between email and username

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Returns the route to go back to after login.
  /// If we came from a course detail "enroll" flow, we want to go back there.
  String? get _returnRoute {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args['returnRoute'] as String?;
    }
    return null;
  }

  String? get _returnArg {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args['returnArg'] as String?;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      identifier: _identifierController.text.trim(), // Changed from email
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        await context.read<EnrollmentProvider>().fetchEnrollments();
        if (!mounted) return;

        // If there's a return route, go back there
        final returnRoute = _returnRoute;
        final returnArg = _returnArg;
        if (returnRoute != null) {
          Navigator.pushReplacementNamed(
            context,
            returnRoute,
            arguments: returnArg,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isTabletLayout = AppResponsive.isTablet(context);
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 40,
    );
    final formMaxWidth = AppResponsive.formMaxWidth(context);

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.school_rounded,
            size: AppResponsive.adaptiveSize(
              context,
              mobile: 72,
              tablet: 84,
              desktop: 88,
            ),
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.welcomeBack,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.signInToContinue,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Toggle between Email and Username
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                AppLocalizations.of(context)!.loginWith,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.email),
                selected: _useEmail,
                onSelected: (selected) {
                  setState(() {
                    _useEmail = true;
                    _identifierController.clear();
                  });
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.username),
                selected: !_useEmail,
                onSelected: (selected) {
                  setState(() {
                    _useEmail = false;
                    _identifierController.clear();
                  });
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Email or Username field
          TextFormField(
            controller: _identifierController,
            keyboardType: _useEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: _useEmail ? AppLocalizations.of(context)!.email : AppLocalizations.of(context)!.username,
              prefixIcon: Icon(
                _useEmail ? Icons.email_outlined : Icons.person_outline,
              ),
              hintText: _useEmail ? AppLocalizations.of(context)!.enterYourEmail : AppLocalizations.of(context)!.enterYourUsername,
            ),
            validator: (value) {
              final l10n = AppLocalizations.of(context)!;
              if (value == null || value.trim().isEmpty) {
                return _useEmail ? l10n.emailRequired : l10n.usernameRequired;
              }
              if (_useEmail && !value.contains('@')) {
                return l10n.enterValidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${AppLocalizations.of(context)!.password} is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text(
                AppLocalizations.of(context)!.forgotPassword,
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Submit
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _submit,
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.signIn),
            ),
          ),
          const SizedBox(height: 16),

          // Register link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              Text(AppLocalizations.of(context)!.dontHaveAccount),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/register',
                    arguments: 'student',
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.signUp,
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isTabletLayout) {
      formContent = Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: formContent,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.signInTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: formContent,
            ),
          ),
        ),
      ),
    );
  }
}
