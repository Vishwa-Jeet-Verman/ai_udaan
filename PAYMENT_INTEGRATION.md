# Razorpay Payment Integration Guide

## Overview
This document describes the Razorpay payment integration for course enrollment in the LMS application.

## Features
- **Free Courses**: Direct enrollment without payment
- **Paid Courses**: Razorpay payment gateway integration
- **Payment Verification**: Server-side signature verification
- **Automatic Enrollment**: Users are enrolled after successful payment
- **Email Notifications**: Confirmation emails sent after enrollment

## Configuration

### Backend Configuration
Add the following to `backend/.env`:
```env
RAZORPAY_KEY_ID=rzp_live_Sf2YaOIoVMjH9B
RAZORPAY_KEY_SECRET=G9D4mfP1ncIvtT1F2KJXXoHq
```

### Frontend Configuration
Add the following to `frontend/.env`:
```env
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_live_Sf2YaOIoVMjH9B
```

## Backend Implementation

### Dependencies
```bash
npm install razorpay
```

### API Endpoints

#### 1. Create Payment Order
**Endpoint**: `POST /api/payments/courses/:courseId/order`

**Headers**:
```
Authorization: Bearer <token>
```

**Response**:
```json
{
  "orderId": "order_xxx",
  "amount": 50000,
  "currency": "INR",
  "keyId": "rzp_live_xxx"
}
```

#### 2. Verify Payment
**Endpoint**: `POST /api/payments/courses/:courseId/verify`

**Headers**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "razorpay_order_id": "order_xxx",
  "razorpay_payment_id": "pay_xxx",
  "razorpay_signature": "signature_xxx"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Payment verified and enrolled successfully.",
  "enrollment": {
    "id": "moodle-1-123",
    "user_id": 1,
    "course_id": "123",
    "enrolled_at": "2024-01-01T00:00:00.000Z",
    "transaction_status": "approved",
    "payment_id": "pay_xxx",
    "order_id": "order_xxx"
  }
}
```

## Frontend Implementation

### Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  razorpay_flutter: ^1.3.7
```

### Flow

1. **User clicks "Enroll Now"**
   - If course is free → Direct enrollment
   - If course is paid → Payment flow

2. **Payment Flow**:
   ```
   User clicks Enroll
   ↓
   Create Order (Backend)
   ↓
   Open Razorpay Checkout
   ↓
   User completes payment
   ↓
   Verify Payment (Backend)
   ↓
   Enroll User in Moodle
   ↓
   Send Notification & Email
   ↓
   Navigate to My Courses
   ```

3. **Payment Success Handler**:
   - Receives payment details from Razorpay
   - Sends to backend for verification
   - Backend verifies signature
   - Backend enrolls user in Moodle
   - Frontend refreshes enrollment list
   - Shows success message

4. **Payment Failure Handler**:
   - Shows error message
   - User can retry payment

## Security

### Backend Security
1. **Signature Verification**: All payments are verified using HMAC SHA256
2. **Authentication**: All endpoints require JWT authentication
3. **Course Validation**: Validates course exists and price matches
4. **Duplicate Check**: Prevents duplicate enrollments

### Signature Verification
```javascript
const body = razorpay_order_id + '|' + razorpay_payment_id;
const expectedSignature = crypto
    .createHmac('sha256', RAZORPAY_KEY_SECRET)
    .update(body.toString())
    .digest('hex');

if (expectedSignature !== razorpay_signature) {
    throw new Error('Invalid signature');
}
```

## Testing

### Test Mode
For testing, use Razorpay test credentials:
```env
RAZORPAY_KEY_ID=rzp_test_xxx
RAZORPAY_KEY_SECRET=test_secret_xxx
```

### Test Cards
- **Success**: 4111 1111 1111 1111
- **Failure**: 4111 1111 1111 1112
- CVV: Any 3 digits
- Expiry: Any future date

## Error Handling

### Common Errors

1. **"This course is free. No payment required."**
   - Attempted to create order for free course
   - Solution: Check course price before initiating payment

2. **"Already enrolled in this course."**
   - User is already enrolled
   - Solution: Check enrollment status before payment

3. **"Invalid payment signature."**
   - Payment verification failed
   - Solution: Check Razorpay credentials

4. **"Payment successful but enrollment failed."**
   - Payment verified but Moodle enrollment failed
   - Solution: Contact support with payment ID

## Platform Support

- ✅ **Android**: Fully supported
- ✅ **iOS**: Fully supported
- ❌ **Web**: Not supported (Razorpay Flutter SDK limitation)

For web, show message: "Payment is not supported on web. Please use the mobile app."

## Notifications

After successful enrollment:
1. **Push Notification**: Real-time notification via Socket.IO
2. **Email**: Confirmation email sent to user's email address

## Logs

Backend logs payment flow:
```
[Payment] 📝 Creating order for user 1, course 123
[Payment] ✅ Order created: order_xxx
[Payment] 🔍 Verifying payment for course 123
[Payment] ✅ Payment verified successfully
[Payment] 🔐 Enrolling user 2 in course 123...
[Payment] 📧 Sending enrollment notification and email...
[Payment] ✅ Successfully enrolled user 2 in course 123
```

## Production Checklist

- [ ] Update Razorpay credentials to live keys
- [ ] Test payment flow end-to-end
- [ ] Verify email notifications work
- [ ] Test with real payment cards
- [ ] Enable webhook for payment status updates (optional)
- [ ] Set up payment reconciliation process
- [ ] Configure refund policy
- [ ] Add payment history page (future enhancement)

## Future Enhancements

1. **Payment History**: Show user's payment transactions
2. **Refunds**: Admin interface for refunds
3. **Webhooks**: Handle payment status updates via webhooks
4. **Multiple Payment Methods**: UPI, Wallets, Net Banking
5. **Discounts & Coupons**: Apply discount codes
6. **Subscription Plans**: Monthly/yearly subscriptions
7. **Web Support**: Integrate Razorpay Standard Checkout for web

## Support

For issues:
1. Check backend logs for payment flow
2. Verify Razorpay credentials
3. Test with Razorpay test mode first
4. Contact Razorpay support for payment gateway issues
