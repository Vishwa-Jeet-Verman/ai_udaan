import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../utils/responsive.dart';

/// Arguments passed to the '/otp-verify' route.
class OtpVerifyArgs {
  final String email;
  final String name;
  final String username;
  final String password;
  final String role;

  const OtpVerifyArgs({
    required this.email,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
  });
}

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  late OtpVerifyArgs _args;
  bool _argsLoaded = false;

  int _resendCountdown = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _args = ModalRoute.of(context)!.settings.arguments as OtpVerifyArgs;
      _argsLoaded = true;
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = _resendCooldownSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final otp = _currentOtp;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(email: _args.email, otp: otp);

    if (!mounted) return;

    if (success) {
      await context.read<EnrollmentProvider>().fetchEnrollments();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
      // Clear boxes on wrong OTP
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _args.name,
      username: _args.username,
      email: _args.email,
      password: _args.password,
      role: _args.role,
    );

    if (!mounted) return;

    if (success) {
      _startResendTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification code has been sent.'),
          backgroundColor: Color(0xFF1F7A63),
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

  void _onDigitChanged(int index, String value) {
    if (value.length == _otpLength) {
      // Handle paste — distribute across boxes
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes.last.requestFocus();
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final maskedEmail = _maskEmail(_args.email);
    final isTabletLayout = AppResponsive.isTablet(context);
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 40,
    );
    final formMaxWidth = AppResponsive.formMaxWidth(context);

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_rounded,
          size: AppResponsive.adaptiveSize(
            context,
            mobile: 72,
            tablet: 84,
            desktop: 88,
          ),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.checkYourEmail,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.verificationCodeSent,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFFD1D5DB)  // High contrast light grey for dark mode
                : const Color(0xFF6B7280), // Dark grey for light mode
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          maskedEmail,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // OTP input boxes
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = AppResponsive.adaptiveSize(
              context,
              mobile: 6,
              tablet: 10,
              desktop: 12,
            );
            final rawWidth =
                (constraints.maxWidth - (spacing * (_otpLength - 1))) /
                _otpLength;
            final boxWidth = rawWidth.clamp(42.0, 56.0).toDouble();

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              children: List.generate(_otpLength, (index) {
                return SizedBox(
                  width: boxWidth,
                  height: 56,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => _onKeyEvent(index, event),
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: index == 0 ? _otpLength : 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  ),
                );
              }),
            );
          },
        ),

        const SizedBox(height: 36),

        // Verify button
        SizedBox(
          width: double.infinity,
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
                : Text(l10n.verifyAndCreate),
          ),
        ),

        const SizedBox(height: 24),

        // Resend
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(l10n.didntReceiveCode, style: theme.textTheme.bodyMedium),
            _resendCountdown > 0
                ? Text(
                    l10n.resendIn(_resendCountdown),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF9CA3AF)  // Medium grey for dark mode
                          : const Color(0xFF9CA3AF), // Medium grey for light mode
                    ),
                  )
                : TextButton(
                    onPressed: authProvider.isLoading ? null : _resend,
                    child: Text(l10n.resend),
                  ),
          ],
        ),
      ],
    );

    if (isTabletLayout) {
      content = Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.verifyEmail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/register',
            arguments: _args.role,
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
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  /// Masks email like  j***e@example.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }
}
