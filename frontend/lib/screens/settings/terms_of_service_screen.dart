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
                  'Last updated: March 9, 2026',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  title: '1. Acceptance of Terms',
                  content:
                      'By accessing and using this Learning Management System (LMS), you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these terms, please do not use this service.',
                ),

                _buildSection(
                  context,
                  title: '2. Use License',
                  content:
                      'Permission is granted to temporarily access the materials (information or software) on NGTech LMS for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                      '• Modify or copy the materials\n'
                      '• Use the materials for commercial purposes\n'
                      '• Attempt to decompile or reverse engineer any software\n'
                      '• Remove any copyright or proprietary notations\n'
                      '• Transfer the materials to another person',
                ),

                _buildSection(
                  context,
                  title: '3. User Account',
                  content:
                      'To access certain features of the service, you must register for an account. You agree to:\n\n'
                      '• Provide accurate, current, and complete information\n'
                      '• Maintain and promptly update your account information\n'
                      '• Maintain the security of your password\n'
                      '• Accept responsibility for all activities under your account\n'
                      '• Notify us immediately of any unauthorized use',
                ),

                _buildSection(
                  context,
                  title: '4. Course Enrollment and Access',
                  content:
                      'When you enroll in a course:\n\n'
                      '• You gain access to course materials for the duration specified\n'
                      '• Access may be revoked for violation of these terms\n'
                      '• Course content is subject to change\n'
                      '• Completion certificates are issued upon meeting requirements\n'
                      '• Refund policies are subject to individual course terms',
                ),

                _buildSection(
                  context,
                  title: '5. User Conduct',
                  content:
                      'You agree not to:\n\n'
                      '• Violate any applicable laws or regulations\n'
                      '• Infringe on intellectual property rights\n'
                      '• Upload malicious code or harmful content\n'
                      '• Harass, threaten, or abuse other users\n'
                      '• Share account credentials\n'
                      '• Use the service for unauthorized commercial purposes\n'
                      '• Collect user data without permission',
                ),

                _buildSection(
                  context,
                  title: '6. Intellectual Property',
                  content:
                      'All course materials, including text, graphics, videos, and other content, are the property of NGTech LMS or its content suppliers and are protected by copyright and intellectual property laws. Unauthorized reproduction or distribution is prohibited.',
                ),

                _buildSection(
                  context,
                  title: '7. Disclaimers',
                  content:
                      'The materials on NGTech LMS are provided on an \'as is\' basis. NGTech LMS makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
                ),

                _buildSection(
                  context,
                  title: '8. Limitations of Liability',
                  content:
                      'In no event shall NGTech LMS or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on NGTech LMS.',
                ),

                _buildSection(
                  context,
                  title: '9. Termination',
                  content:
                      'We may terminate or suspend your account and access to the service immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the service will cease immediately.',
                ),

                _buildSection(
                  context,
                  title: '10. Changes to Terms',
                  content:
                      'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days\' notice prior to any new terms taking effect. Continued use of the service after changes constitutes acceptance of the new terms.',
                ),

                _buildSection(
                  context,
                  title: '11. Governing Law',
                  content:
                      'These Terms shall be governed and construed in accordance with the laws of the jurisdiction in which NGTech LMS operates, without regard to its conflict of law provisions.',
                ),

                _buildSection(
                  context,
                  title: '12. Contact Information',
                  content:
                      'If you have any questions about these Terms, please contact us:\n\n'
                      'Email: legal@ngtech.com\n'
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
