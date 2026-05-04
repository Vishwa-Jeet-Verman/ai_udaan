# Payment Flow Diagram

## Complete Payment Integration Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER CLICKS "ENROLL NOW"                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   Check if User is Logged In  │
                    └───────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
            ┌──────────────┐              ┌──────────────────┐
            │  Not Logged  │              │   Logged In      │
            │      In      │              │                  │
            └──────────────┘              └──────────────────┘
                    │                               │
                    ▼                               ▼
        ┌──────────────────────┐      ┌──────────────────────────┐
        │ Redirect to Login    │      │  Check Course Price      │
        │ with Return Route    │      │                          │
        └──────────────────────┘      └──────────────────────────┘
                                                    │
                                    ┌───────────────┴───────────────┐
                                    │                               │
                                    ▼                               ▼
                        ┌──────────────────┐          ┌──────────────────────┐
                        │   FREE COURSE    │          │    PAID COURSE       │
                        │   (price = 0)    │          │    (price > 0)       │
                        └──────────────────┘          └──────────────────────┘
                                    │                               │
                                    │                               │
╔═══════════════════════════════════╧═══════════════════════════════╧═══════════════════════════════╗
║                                                                                                    ║
║  FREE COURSE FLOW                                    PAID COURSE FLOW                             ║
║  ─────────────────                                   ─────────────────                            ║
║                                                                                                    ║
║  1. Call Backend Enroll API                          1. Call Backend Create Order API            ║
║     POST /api/courses/:id/enroll                        POST /api/payments/courses/:id/order     ║
║                                                                                                    ║
║  2. Backend enrolls in Moodle                        2. Backend creates Razorpay order           ║
║                                                          - Validates course price                 ║
║  3. Send notification & email                           - Checks not already enrolled            ║
║                                                          - Creates order with Razorpay            ║
║  4. Return success                                                                                ║
║                                                       3. Return order details to frontend         ║
║  5. Frontend shows success                              { orderId, amount, currency, keyId }     ║
║                                                                                                    ║
║  6. Navigate to My Courses                           4. Frontend opens Razorpay Checkout         ║
║                                                          - User enters card details               ║
║                                                          - User completes payment                 ║
║                                                                                                    ║
║                                                       5. Razorpay returns payment response        ║
║                                                          - Success: { paymentId, orderId,         ║
║                                                                      signature }                  ║
║                                                          - Failure: { error message }             ║
║                                                                                                    ║
║                                                       6. Frontend calls Verify Payment API        ║
║                                                          POST /api/payments/courses/:id/verify    ║
║                                                          Body: { orderId, paymentId, signature }  ║
║                                                                                                    ║
║                                                       7. Backend verifies signature               ║
║                                                          - HMAC SHA256 verification               ║
║                                                          - Validates payment authenticity         ║
║                                                                                                    ║
║                                                       8. Backend enrolls user in Moodle           ║
║                                                                                                    ║
║                                                       9. Send notification & email                ║
║                                                                                                    ║
║                                                       10. Return success with enrollment          ║
║                                                                                                    ║
║                                                       11. Frontend shows success                  ║
║                                                                                                    ║
║                                                       12. Navigate to My Courses                  ║
║                                                                                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════╝
```

## Detailed Component Interaction

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │         │              │         │              │         │              │
│   Flutter    │────────▶│   Backend    │────────▶│   Razorpay   │────────▶│   Moodle     │
│   Frontend   │◀────────│   Server     │◀────────│   Gateway    │◀────────│   LMS        │
│              │         │              │         │              │         │              │
└──────────────┘         └──────────────┘         └──────────────┘         └──────────────┘
       │                        │                        │                        │
       │                        │                        │                        │
       │  1. Create Order       │                        │                        │
       │───────────────────────▶│                        │                        │
       │                        │  2. Create Order       │                        │
       │                        │───────────────────────▶│                        │
       │                        │  3. Order Details      │                        │
       │  4. Order Details      │◀───────────────────────│                        │
       │◀───────────────────────│                        │                        │
       │                        │                        │                        │
       │  5. Open Checkout      │                        │                        │
       │───────────────────────────────────────────────▶│                        │
       │                        │                        │                        │
       │  6. User Pays          │                        │                        │
       │◀───────────────────────────────────────────────│                        │
       │                        │                        │                        │
       │  7. Verify Payment     │                        │                        │
       │───────────────────────▶│                        │                        │
       │                        │  8. Verify Signature   │                        │
       │                        │───────────────────────▶│                        │
       │                        │  9. Verified           │                        │
       │                        │◀───────────────────────│                        │
       │                        │                        │                        │
       │                        │  10. Enroll User       │                        │
       │                        │───────────────────────────────────────────────▶│
       │                        │  11. Enrollment Success│                        │
       │                        │◀───────────────────────────────────────────────│
       │                        │                        │                        │
       │  12. Success Response  │                        │                        │
       │◀───────────────────────│                        │                        │
       │                        │                        │                        │
```

## Security Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PAYMENT SIGNATURE VERIFICATION                    │
└─────────────────────────────────────────────────────────────────────┘

1. Razorpay generates signature:
   ┌──────────────────────────────────────────────────────────┐
   │  signature = HMAC_SHA256(                                │
   │      key: RAZORPAY_KEY_SECRET,                           │
   │      message: order_id + "|" + payment_id                │
   │  )                                                        │
   └──────────────────────────────────────────────────────────┘

2. Frontend receives:
   ┌──────────────────────────────────────────────────────────┐
   │  {                                                        │
   │    razorpay_order_id: "order_xxx",                       │
   │    razorpay_payment_id: "pay_xxx",                       │
   │    razorpay_signature: "generated_signature"             │
   │  }                                                        │
   └──────────────────────────────────────────────────────────┘

3. Backend verifies:
   ┌──────────────────────────────────────────────────────────┐
   │  expected_signature = HMAC_SHA256(                       │
   │      key: RAZORPAY_KEY_SECRET,                           │
   │      message: order_id + "|" + payment_id                │
   │  )                                                        │
   │                                                           │
   │  if (expected_signature === received_signature) {        │
   │      // Payment is authentic                             │
   │      enrollUser()                                        │
   │  } else {                                                 │
   │      // Payment is fraudulent                            │
   │      rejectPayment()                                     │
   │  }                                                        │
   └──────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ERROR SCENARIOS                              │
└─────────────────────────────────────────────────────────────────────┘

1. Course Not Found
   User → Frontend → Backend → ❌ 404 Error
                              └─▶ "Course not found"

2. Already Enrolled
   User → Frontend → Backend → Check Moodle → ❌ 400 Error
                                             └─▶ "Already enrolled"

3. Payment Failure
   User → Frontend → Razorpay → ❌ Payment Failed
                              └─▶ Show error message
                              └─▶ User can retry

4. Invalid Signature
   User → Frontend → Backend → Verify → ❌ 400 Error
                                       └─▶ "Invalid payment signature"

5. Enrollment Failed After Payment
   User → Frontend → Backend → Verify ✅ → Enroll → ❌ 502 Error
                                                   └─▶ "Payment successful but 
                                                        enrollment failed. 
                                                        Contact support."
```

## State Management

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FRONTEND STATE TRANSITIONS                        │
└─────────────────────────────────────────────────────────────────────┘

Initial State:
  _isEnrolled = false
  _isEnrolling = false

User Clicks Enroll:
  _isEnrolling = true

Payment Success:
  _isEnrolling = true (still loading)
  → Verify payment
  → Fetch enrollments
  → _isEnrolled = true
  → _isEnrolling = false
  → Navigate to My Courses

Payment Failure:
  _isEnrolling = false
  → Show error message
  → User can retry
```

## Backend Logging Flow

```
[Payment] 📝 Creating order for user 1, course 123
[Payment] ✅ Order created: order_MxYz123
[Payment] 🔍 Verifying payment for course 123
[Payment] ✅ Payment verified successfully
[Payment] 🔐 Enrolling user 2 in course 123...
[Payment] 📧 Sending enrollment notification and email...
[Payment] ✅ Email sent to user@example.com
[Payment] ✅ Successfully enrolled user 2 in course 123
```

## Platform-Specific Behavior

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PLATFORM SUPPORT MATRIX                         │
└─────────────────────────────────────────────────────────────────────┘

Android:
  ✅ Razorpay SDK fully supported
  ✅ Native payment UI
  ✅ All payment methods available

iOS:
  ✅ Razorpay SDK fully supported
  ✅ Native payment UI
  ✅ All payment methods available

Web:
  ❌ Razorpay Flutter SDK not supported
  ℹ️  Shows message: "Payment not supported on web. Use mobile app."
  💡 Future: Can integrate Razorpay Standard Checkout for web
```
