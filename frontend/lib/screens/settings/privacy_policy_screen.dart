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
                  'Last updated: March 9, 2026',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  title: '1. Information We Collect',
                  content:
                      'We collect information that you provide directly to us, including:\n\n'
                      '• Personal information (name, email address, phone number)\n'
                      '• Educational information (courses, grades, progress)\n'
                      '• Account credentials\n'
                      '• Profile information and preferences\n'
                      '• Communication and interaction data',
                ),

                _buildSection(
                  context,
                  title: '2. How We Use Your Information',
                  content:
                      'We use the information we collect to:\n\n'
                      '• Provide, maintain, and improve our services\n'
                      '• Process enrollments and track progress\n'
                      '• Send you course updates and notifications\n'
                      '• Respond to your comments and questions\n'
                      '• Protect against fraudulent or illegal activity\n'
                      '• Comply with legal obligations',
                ),

                _buildSection(
                  context,
                  title: '3. Information Sharing',
                  content:
                      'We do not sell your personal information. We may share your information:\n\n'
                      '• With instructors for enrolled courses\n'
                      '• With service providers who assist our operations\n'
                      '• When required by law or to protect rights\n'
                      '• With your consent or at your direction',
                ),

                _buildSection(
                  context,
                  title: '4. Data Security',
                  content:
                      'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                ),

                _buildSection(
                  context,
                  title: '5. Your Rights',
                  content:
                      'You have the right to:\n\n'
                      '• Access your personal information\n'
                      '• Correct inaccurate data\n'
                      '• Request deletion of your data\n'
                      '• Object to processing of your data\n'
                      '• Export your data\n'
                      '• Withdraw consent',
                ),

                _buildSection(
                  context,
                  title: '6. Cookies and Tracking',
                  content:
                      'We use cookies and similar tracking technologies to track activity on our service and hold certain information. You can instruct your browser to refuse all cookies or indicate when a cookie is being sent.',
                ),

                _buildSection(
                  context,
                  title: '7. Children\'s Privacy',
                  content:
                      'Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
                ),

                _buildSection(
                  context,
                  title: '8. Changes to This Policy',
                  content:
                      'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                ),

                _buildSection(
                  context,
                  title: '9. Contact Us',
                  content:
                      'If you have any questions about this Privacy Policy, please contact us:\n\n'
                      'Email: privacy@ngtech.com\n'
                      'Phone: +1 (555) 123-4567\n'
                      'Address: 123 Education St, Learning City, LC 12345',
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
