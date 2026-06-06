import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                  'Terms of Service',
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
                  title: '1. Acceptance of Terms',
                  content:
                      'By downloading, installing, or using the AI UDAAN app ("App"), you agree to be bound by '
                      'these Terms of Service ("Terms"). These Terms apply to all users of the App, including '
                      'learners, guests, and any other individuals who access our services.\n\n'
                      'If you do not agree to these Terms, do not use the App.',
                ),

                _buildSection(
                  context,
                  title: '2. About AI UDAAN',
                  content:
                      'AI UDAAN is an online learning platform operated by AI Learn NG LMS, hosted at '
                      'Buddha Institute of Technology, Gaya Ji, Bihar, India. The platform provides access '
                      'to AI, machine learning, deep learning, and related technology courses — both free '
                      'and paid — delivered through Moodle LMS.',
                ),

                _buildSection(
                  context,
                  title: '3. Eligibility',
                  content:
                      'To use this App you must:\n\n'
                      '• Be at least 13 years of age\n'
                      '• Provide accurate and complete registration information\n'
                      '• Keep your account credentials confidential\n'
                      '• Not share your account with any other person\n\n'
                      'By registering, you confirm that all information you provide is truthful and accurate.',
                ),

                _buildSection(
                  context,
                  title: '4. Account Registration',
                  content:
                      'You must create an account to access courses and track your progress. You are responsible '
                      'for all activity that occurs under your account. If you suspect unauthorized use of your '
                      'account, contact us immediately at info@aiudaanbootcamp.com.\n\n'
                      'We reserve the right to suspend or terminate accounts that violate these Terms.',
                ),

                _buildSection(
                  context,
                  title: '5. Course Enrollment & Access',
                  content:
                      'Free courses are available to all registered users at no charge. Paid courses require '
                      'payment before access is granted.\n\n'
                      '• Upon successful enrollment, you are granted a personal, non-transferable license to '
                      'access course content for your own learning.\n'
                      '• Course access is tied to your account and may not be shared or transferred.\n'
                      '• We reserve the right to modify, update, or discontinue course content at any time.\n'
                      '• Enrollment is managed through Moodle LMS. Access issues should be reported to support.',
                ),

                _buildSection(
                  context,
                  title: '6. Payments & Refunds',
                  content:
                      'All payments for paid courses are processed securely through Razorpay in Indian Rupees (₹).\n\n'
                      '• Prices are displayed on the course listing before purchase.\n'
                      '• Once a payment is verified and enrollment is confirmed, it is considered final.\n'
                      '• Refunds are not automatically provided. If you face a payment or enrollment issue, '
                      'contact us at info@aiudaanbootcamp.com within 7 days of the transaction.\n'
                      '• We are not responsible for payment failures caused by your bank, network issues, '
                      'or incorrect payment details.',
                ),

                _buildSection(
                  context,
                  title: '7. Intellectual Property',
                  content:
                      'All content on the AI UDAAN platform — including course material, videos, text, graphics, '
                      'logos, and the App itself — is the property of AI Learn NG LMS or its content providers '
                      'and is protected by applicable intellectual property laws.\n\n'
                      'You may not:\n\n'
                      '• Copy, reproduce, or redistribute course content\n'
                      '• Use course material for commercial purposes\n'
                      '• Reverse-engineer or attempt to extract the App\'s source code\n'
                      '• Share access credentials or enrolled course content with others',
                ),

                _buildSection(
                  context,
                  title: '8. Prohibited Conduct',
                  content:
                      'When using AI UDAAN, you agree not to:\n\n'
                      '• Violate any applicable laws or regulations\n'
                      '• Attempt to gain unauthorized access to other accounts or backend systems\n'
                      '• Upload or transmit harmful, offensive, or malicious content\n'
                      '• Interfere with the App\'s functionality or infrastructure\n'
                      '• Use automated tools or bots to scrape content or enroll in courses\n'
                      '• Impersonate any person or entity',
                ),

                _buildSection(
                  context,
                  title: '9. Notifications & Communications',
                  content:
                      'By creating an account, you consent to receiving:\n\n'
                      '• Enrollment confirmation emails\n'
                      '• Course update and progress notifications via the App\n'
                      '• Important service announcements\n\n'
                      'You can manage notification preferences in Settings → Notifications. '
                      'You may opt out of marketing communications at any time.',
                ),

                _buildSection(
                  context,
                  title: '10. Disclaimers',
                  content:
                      'The App and all content are provided "as is" without any warranty of any kind. '
                      'AI Learn NG LMS does not guarantee:\n\n'
                      '• Uninterrupted or error-free access to the platform\n'
                      '• That course content will meet your specific learning objectives\n'
                      '• Employment or certification outcomes from completing courses\n\n'
                      'Use of the platform is at your own risk.',
                ),

                _buildSection(
                  context,
                  title: '11. Limitation of Liability',
                  content:
                      'To the fullest extent permitted by law, AI Learn NG LMS shall not be liable for any '
                      'indirect, incidental, or consequential damages arising from your use of the App, '
                      'including loss of data, enrollment errors, or payment disputes beyond amounts '
                      'actually paid by you for the affected course.',
                ),

                _buildSection(
                  context,
                  title: '12. Governing Law',
                  content:
                      'These Terms are governed by the laws of India. Any disputes arising from these Terms '
                      'or your use of the App shall be subject to the exclusive jurisdiction of the courts '
                      'in Bihar, India.',
                ),

                _buildSection(
                  context,
                  title: '13. Changes to These Terms',
                  content:
                      'We may update these Terms of Service from time to time. Changes take effect immediately '
                      'upon posting in the App. Continued use of the App after changes are posted constitutes '
                      'your acceptance of the updated Terms.',
                ),

                _buildSection(
                  context,
                  title: '14. Contact Us',
                  content:
                      'For any questions or concerns regarding these Terms, please reach out:\n\n'
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
