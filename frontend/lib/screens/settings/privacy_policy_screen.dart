import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 860,
      desktop: 980,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: June 6, 2026',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  title: '1. Introduction',
                  content:
                      'AI Learn NG LMS ("Company", "we", "our", or "us") operates as an online learning platform. '
                      'This Privacy Policy explains how we collect, use, disclose, and otherwise handle personal '
                      'information when you use our website and services.',
                ),

                _buildSection(
                  context,
                  title: '2. Information We Collect',
                  content:
                      'We collect information in various ways:\n\n'
                      '• Personal Information: When you create an account, we collect your name, email address, '
                      'password, and profile information.\n'
                      '• Usage Data: We automatically collect information about how you interact with our platform, '
                      'including courses viewed and progress made.\n'
                      '• Device Information: We collect information about your device, including IP address, '
                      'browser type, and operating system.',
                ),

                _buildSection(
                  context,
                  title: '3. How We Use Your Information',
                  content:
                      'We use the information we collect for:\n\n'
                      '• Creating and maintaining your account\n'
                      '• Delivering and improving our services\n'
                      '• Personalizing your learning experience\n'
                      '• Sending you educational content and updates\n'
                      '• Responding to your inquiries\n'
                      '• Complying with legal obligations',
                ),

                _buildSection(
                  context,
                  title: '4. Data Security',
                  content:
                      'We implement appropriate technical and organizational measures to protect your personal '
                      'information against unauthorized access, alteration, disclosure, or destruction. '
                      'However, no method of transmission over the Internet is 100% secure.',
                ),

                _buildSection(
                  context,
                  title: '5. Third-Party Sharing',
                  content:
                      'We do not sell, trade, or rent your personal information to third parties. We may share '
                      'information with service providers who assist us in operating our website and conducting '
                      'our business, under strict confidentiality agreements.',
                ),

                _buildSection(
                  context,
                  title: '6. Cookies',
                  content:
                      'Our website uses cookies to enhance your experience. You can choose to disable cookies '
                      'through your browser settings, though this may limit your ability to use certain features.',
                ),

                _buildSection(
                  context,
                  title: '7. Your Rights',
                  content:
                      'You have the right to:\n\n'
                      '• Access your personal information\n'
                      '• Correct inaccurate information\n'
                      '• Request deletion of your data\n'
                      '• Opt-out of marketing communications',
                ),

                _buildSection(
                  context,
                  title: '8. Changes to This Policy',
                  content:
                      'We reserve the right to modify this Privacy Policy at any time. Changes will be effective '
                      'immediately upon posting to the website. Your continued use of the platform following the '
                      'posting of revised Privacy Policy means you accept and agree to the changes.',
                ),

                _buildSection(
                  context,
                  title: '9. Contact Us',
                  content:
                      'If you have questions about this Privacy Policy, please contact us:\n\n'
                      'Email: info@aiudaanbootcamp.com\n'
                      'Address: Buddha Institute of Technology, Gaya Ji, Bihar, India',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
