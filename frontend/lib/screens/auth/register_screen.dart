import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/password_validator.dart';
import '../../utils/responsive.dart';
import '../auth/otp_verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isCheckingEmail = false;
  String? _lastCheckedEmail;
  String? _lastEmailError;
  String? _lastValidatedName;
  String? _lastValidatedUsername;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_handleNameFocusChange);
    _nameController.addListener(_handleNameChanged);
    _usernameFocusNode.addListener(_handleUsernameFocusChange);
    _usernameController.addListener(_handleUsernameChanged);
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _emailController.addListener(_handleEmailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedRole ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_handleNameFocusChange);
    _nameController.removeListener(_handleNameChanged);
    _usernameFocusNode.removeListener(_handleUsernameFocusChange);
    _usernameController.removeListener(_handleUsernameChanged);
    _emailFocusNode.removeListener(_handleEmailFocusChange);
    _emailController.removeListener(_handleEmailChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  String? _getNameValidationMessage(String name) {
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedName.isEmpty) {
      return 'Name is required';
    }

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(normalizedName)) {
      return 'Name can contain only letters and spaces';
    }

    if (normalizedName.replaceAll(RegExp(r'\s+'), '').length < 3) {
      return 'Name must be at least 3 characters long';
    }

    return null;
  }

  bool _validateName({bool showToast = false}) {
    final errorMessage = _getNameValidationMessage(_nameController.text);
    if (errorMessage != null) {
      if (showToast) {
        _showErrorToast(errorMessage);
      }
      if (mounted) setState(() => _lastValidatedName = null);
      return false;
    }
    if (mounted) setState(() => _lastValidatedName = _nameController.text);
    return true;
  }

  String? _getUsernameValidationMessage(String username) {
    final normalizedUsername = _normalizeUsername(username);

    if (normalizedUsername.isEmpty) {
      return 'Username is required';
    }

    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(normalizedUsername)) {
      return 'Username can use only letters, numbers, dots, underscores, and hyphens';
    }

    if (normalizedUsername.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (normalizedUsername.length > 40) {
      return 'Username must be at most 40 characters long';
    }

    if (RegExp(r'^[._-]|[._-]$').hasMatch(normalizedUsername)) {
      return 'Username cannot start or end with a dot, underscore, or hyphen';
    }

    return null;
  }

  bool _validateUsername({bool showToast = false}) {
    final normalizedUsername = _normalizeUsername(_usernameController.text);
    final errorMessage = _getUsernameValidationMessage(normalizedUsername);
    if (errorMessage != null) {
      if (showToast) {
        _showErrorToast(errorMessage);
      }
      if (mounted) setState(() => _lastValidatedUsername = null);
      return false;
    }

    if (_usernameController.text != normalizedUsername) {
      _usernameController.value = TextEditingValue(
        text: normalizedUsername,
        selection: TextSelection.collapsed(offset: normalizedUsername.length),
      );
    }

    if (mounted) setState(() => _lastValidatedUsername = normalizedUsername);
    return true;
  }

  bool _validateEmailInput({bool showToast = false}) {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      if (showToast) {
        _showErrorToast('Email is required');
      }
      return false;
    }

    if (!_looksLikeValidEmail(email)) {
      if (showToast) {
        _showErrorToast('Enter a valid email');
      }
      return false;
    }

    return true;
  }

  void _handleNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _validateName(showToast: true);
    }
  }

  void _handleNameChanged() {
    final currentName = _nameController.text;
    if (_lastValidatedName != null && _lastValidatedName != currentName) {
      setState(() => _lastValidatedName = null);
    }
  }

  void _handleUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus) {
      _validateUsername(showToast: true);
    }
  }

  void _handleUsernameChanged() {
    final currentUsername = _normalizeUsername(_usernameController.text);
    if (_lastValidatedUsername != null &&
        _lastValidatedUsername != currentUsername) {
      setState(() => _lastValidatedUsername = null);
    }
  }

  void _handleEmailChanged() {
    final currentEmail = _emailController.text.trim();
    if (_lastCheckedEmail != currentEmail) {
      _lastCheckedEmail = null;
      _lastEmailError = null;
    }
  }

  void _handleEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      if (!_validateName(showToast: true)) {
        return;
      }
      if (!_validateUsername(showToast: true)) {
        return;
      }
      _checkEmailAvailability(showToast: true);
    }
  }

  bool _looksLikeValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool get _hasValidatedName {
    final currentName = _nameController.text;
    return _lastValidatedName != null && _lastValidatedName == currentName;
  }

  bool get _hasValidatedUsername {
    final currentUsername = _normalizeUsername(_usernameController.text);
    return _lastValidatedUsername != null &&
        _lastValidatedUsername == currentUsername;
  }

  bool get _hasValidatedEmail {
    final currentEmail = _emailController.text.trim();
    return !_isCheckingEmail &&
        currentEmail.isNotEmpty &&
        _lastCheckedEmail == currentEmail &&
        _lastEmailError == null;
  }

  void _showErrorToast(String message, {Duration? duration}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _checkEmailAvailability({bool showToast = false}) async {
    final email = _emailController.text.trim();

    if (!_validateEmailInput(showToast: showToast)) {
      return false;
    }

    if (_lastCheckedEmail == email) {
      if (_lastEmailError != null && showToast) {
        _showErrorToast(_lastEmailError!);
      }
      return _lastEmailError == null;
    }

    if (_isCheckingEmail) {
      return false;
    }

    setState(() {
      _isCheckingEmail = true;
    });

    try {
      await AuthService.checkEmailStatus(email: email, purpose: 'register');
      _lastCheckedEmail = email;
      _lastEmailError = null;
      return true;
    } on ApiException catch (e) {
      _lastCheckedEmail = email;
      _lastEmailError = e.message;
      if (showToast) {
        _showErrorToast(e.message);
      }
      return false;
    } catch (_) {
      if (showToast) {
        _showErrorToast(
          'Unable to validate email right now. Please try again.',
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final nameOk = _validateName(showToast: true);
    if (!nameOk) {
      return;
    }

    final usernameOk = _validateUsername(showToast: true);
    if (!usernameOk) {
      return;
    }

    final emailInputOk = _validateEmailInput(showToast: true);
    if (!emailInputOk) {
      return;
    }

    final emailOk = await _checkEmailAvailability(showToast: true);
    if (!mounted) return;
    if (!emailOk) {
      return;
    }

    // Validate password before proceeding
    final passwordValidation = PasswordValidator.validatePassword(password);
    if (!passwordValidation.isValid) {
      _showErrorToast(
        passwordValidation.errors.join('\n'),
        duration: const Duration(seconds: 5),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showErrorToast('Please confirm your password');
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      _showErrorToast('Passwords do not match');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      username: _normalizeUsername(_usernameController.text),
      email: email,
      password: password,
      role: _selectedRole ?? 'student',
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(
        context,
        '/otp-verify',
        arguments: OtpVerifyArgs(
          email: authProvider.pendingEmail ?? _emailController.text.trim(),
          name: _nameController.text.trim(),
          username: _normalizeUsername(_usernameController.text),
          password: password,
          role: _selectedRole ?? 'student',
        ),
      );
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
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
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.createAccount,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.startLearning,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Name
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fullName,
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: _hasValidatedName
                  ? const Icon(Icons.check_circle, color: Color(0xFF1F7A63))
                  : null,
              helperText: _hasValidatedName ? AppLocalizations.of(context)!.looksGood : null,
              helperStyle: const TextStyle(color: Color(0xFF1F7A63)),
            ),
            validator: (value) => null,
          ),
          const SizedBox(height: 16),

          // Username
          TextFormField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.username,
              prefixIcon: const Icon(Icons.alternate_email_outlined),
              suffixIcon: _hasValidatedUsername
                  ? const Icon(Icons.check_circle, color: Color(0xFF1F7A63))
                  : null,
              helperText: _hasValidatedUsername ? AppLocalizations.of(context)!.looksGood : null,
              helperStyle: const TextStyle(color: Color(0xFF1F7A63)),
            ),
            validator: (value) => null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              prefixIcon: const Icon(Icons.email_outlined),
              suffixIcon: _isCheckingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _hasValidatedEmail
                  ? const Icon(Icons.check_circle, color: Color(0xFF1F7A63))
                  : null,
              helperText: _hasValidatedEmail ? AppLocalizations.of(context)!.looksGood : null,
              helperStyle: const TextStyle(color: Color(0xFF1F7A63)),
            ),
            validator: (value) => null,
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
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.confirmPassword,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              return null;
            },
          ),
          const SizedBox(height: 24),

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
                  : Text(AppLocalizations.of(context)!.signUp),
            ),
          ),
          const SizedBox(height: 16),

          // Login link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              Text(AppLocalizations.of(context)!.alreadyHaveAccount),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                    arguments: _selectedRole,
                  );
                },
                child: Text(AppLocalizations.of(context)!.signIn),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.createAccount),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: _selectedRole,
          ),
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
