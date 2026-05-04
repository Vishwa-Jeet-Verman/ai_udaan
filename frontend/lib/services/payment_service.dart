import '../config/api_config.dart';
import 'api_service.dart';

class PaymentService {
  /// Create a Razorpay order for course enrollment
  static Future<Map<String, dynamic>> createOrder(String courseId) async {
    final data = await ApiService.post(
      '${ApiConfig.baseUrl}/payments/courses/$courseId/order',
      auth: true,
    );
    return data;
  }

  /// Verify payment and enroll user
  static Future<Map<String, dynamic>> verifyPayment(
    String courseId,
    String orderId,
    String paymentId,
    String signature,
  ) async {
    final data = await ApiService.post(
      '${ApiConfig.baseUrl}/payments/courses/$courseId/verify',
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      auth: true,
    );
    return data;
  }
}
