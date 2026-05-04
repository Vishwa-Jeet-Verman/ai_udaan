import 'api_service.dart';
import '../config/api_config.dart';

class SupportService {
  static Future<void> sendSupportEmail({
    required String userEmail,
    required String userName,
    required String subject,
    required String message,
  }) async {
    try {
      await ApiService.post(
        '${ApiConfig.baseUrl}/support/send',
        body: {
          'userEmail': userEmail,
          'userName': userName,
          'subject': subject,
          'message': message,
        },
        auth: true,
      );
    } catch (e) {
      throw Exception('Failed to send support email: $e');
    }
  }
}
