import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/password_validator.dart';
import '../../utils/responsive.dart';

enum _Step { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;

  // Step 1
  final _emailController = TextEditingController();
  // Step 2
  final _otpController = TextEditingController();
  // Step 3
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
  }

  // ── Step 1: request OTP ───────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email address.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(email: email);
      _email = email;
      setState(() { _step = _Step.otp; _isLoading = false; });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message);
    } catch (_) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  // ── Step 2: verify OTP ────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Enter the 6-digit code sent to your email.');
      return;
    }
    // Just move to next step — OTP is verified together with new password
    setState(() => _step = _Step.newPassword);
  }

  // ── Step 3: reset password ────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final otp = _otpController.text.trim();

    final validation = PasswordValidator.validatePassword(password);
    if (!validation.isValid) {
      _showError(validation.errors.join('\n'));
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(email: _email, otp: otp, newPassword: password);
      setState(() { _isLoading = false; _isSuccess = true; });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      // If OTP is wrong/expired, go back to OTP step
      if (e.message.toLowerCase().contains('code') ||
          e.message.toLowerCase().contains('otp') ||
          e.message.toLowerCase().contains('expired')) {
        setState(() => _step = _Step.otp);
      }
      _showError(e.message);
    } catch (_) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(
      context, mobile: 20, tablet: 32, desktop: 40,
    );
    final formMaxWidth = AppResponsive.formMaxWidth(context);

    Widget body;
    if (_isSuccess) {
      body = _buildSuccess();
    } else if (_step == _Step.email) {
      body = _buildEmailStep();
    } else if (_step == _Step.otp) {
      body = _buildOtpStep();
    } else {
      body = _buildNewPasswordStep();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == _Step.otp) {
              setState(() => _step = _Step.email);
            } else if (_step == _Step.newPassword) {
              setState(() => _step = _Step.otp);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(AppLocalizations.of(context)!.resetPassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────
  Widget _buildEmailStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset_rounded, size: 72, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text(l10n.forgotPasswordTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l10n.forgotPasswordSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onSubmitted: (_) => _sendOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.sendResetCode),
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI ─────────────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 72, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text(l10n.checkEmailTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l10n.checkEmailSubtitle(_email),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
          decoration: InputDecoration(
            labelText: l10n.resetCode,
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            child: Text(l10n.continueLabel),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: Text(l10n.resendCode),
        ),
      ],
    );
  }

  // ── Step 3 UI ─────────────────────────────────────────────────────────────
  Widget _buildNewPasswordStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline_rounded, size: 72, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        Text(l10n.setNewPassword,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l10n.setNewPasswordSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: l10n.confirmNewPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.resetPassword),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1F7A63).withAlpha(25), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF1F7A63)),
        ),
        const SizedBox(height: 24),
        Text(l10n.passwordReset,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          l10n.passwordResetSuccess,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.backToSignIn),
          ),
        ),
      ],
    );
  }
}
