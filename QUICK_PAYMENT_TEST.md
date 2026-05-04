# Quick Payment Integration Test Guide

## 🚀 Quick Start (5 minutes)

### 1. Start Backend
```bash
cd backend
npm run dev
```

Expected output:
```
╔══════════════════════════════════════════════════╗
║        LMS Backend — Moodle-Only Runtime         ║
╠══════════════════════════════════════════════════╣
║  API   →  http://localhost:9000/api              ║
║  Files →  http://localhost:9000/uploads/         ║
║  DB    →  disabled                               ║
╚══════════════════════════════════════════════════╝
```

### 2. Start Frontend
```bash
cd frontend
flutter run
```

### 3. Test Free Course Enrollment

1. Login to the app
2. Browse courses
3. Select a **FREE** course (price = ₹0)
4. Click "Enroll Now"
5. ✅ Should enroll directly without payment

**Expected Flow:**
```
Click Enroll → Loading → Success Message → Navigate to My Courses
```

### 4. Test Paid Course Enrollment

1. Browse courses
2. Select a **PAID** course (price > ₹0)
3. Click "Enroll Now"
4. Razorpay checkout should open
5. Use test card: **4111 1111 1111 1111**
6. CVV: **123**
7. Expiry: Any future date (e.g., 12/25)
8. Click Pay
9. ✅ Payment should succeed and enroll you

**Expected Flow:**
```
Click Enroll → Create Order → Razorpay Opens → Enter Card → Pay → 
Verify Payment → Enroll → Success → Navigate to My Courses
```

## 🧪 Test Scenarios

### ✅ Scenario 1: Free Course
- **Action**: Enroll in free course
- **Expected**: Direct enrollment, no payment
- **Backend Log**: `[Enroll] ✅ Successfully enrolled`

### ✅ Scenario 2: Paid Course - Success
- **Action**: Enroll with test card 4111 1111 1111 1111
- **Expected**: Payment success, enrollment complete
- **Backend Logs**:
  ```
  [Payment] 📝 Creating order for user X, course Y
  [Payment] ✅ Order created: order_xxx
  [Payment] 🔍 Verifying payment for course Y
  [Payment] ✅ Payment verified successfully
  [Payment] 🔐 Enrolling user X in course Y...
  [Payment] ✅ Successfully enrolled
  ```

### ✅ Scenario 3: Paid Course - Failure
- **Action**: Enroll with test card 4111 1111 1111 1112
- **Expected**: Payment fails, no enrollment
- **Frontend**: Shows error message

### ✅ Scenario 4: Already Enrolled
- **Action**: Try to enroll in already enrolled course
- **Expected**: Shows "Already enrolled" message

### ✅ Scenario 5: Web Platform
- **Action**: Try to enroll in paid course on web
- **Expected**: Shows "Payment not supported on web" message

## 🔍 Debugging

### Check Backend Logs
Look for these prefixes:
- `[Payment]` - Payment flow logs
- `[Enroll]` - Enrollment logs

### Common Issues

#### 1. "Failed to create order"
**Cause**: Razorpay credentials not set or invalid
**Fix**: Check `backend/.env` has correct credentials

#### 2. "Invalid payment signature"
**Cause**: Razorpay secret key mismatch
**Fix**: Verify `RAZORPAY_KEY_SECRET` in `backend/.env`

#### 3. Razorpay doesn't open
**Cause**: Missing key in frontend
**Fix**: Check `frontend/.env` has `NEXT_PUBLIC_RAZORPAY_KEY_ID`

#### 4. "Payment not supported on web"
**Cause**: Running on web browser
**Fix**: Use Android/iOS emulator or device

## 📊 Test Checklist

- [ ] Backend starts without errors
- [ ] Frontend builds and runs
- [ ] Can login successfully
- [ ] Can view course list
- [ ] Free course enrolls directly
- [ ] Paid course opens Razorpay
- [ ] Test payment succeeds
- [ ] User gets enrolled after payment
- [ ] Email notification received
- [ ] Course appears in "My Courses"
- [ ] Backend logs show payment flow

## 🎯 Quick Verification

### Backend Health Check
```bash
curl http://localhost:9000/api/health
```

Expected:
```json
{
  "status": "OK",
  "database": "Moodle API only (no local DB)",
  "storage": "Local disk (/uploads)",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Test Order Creation (with auth token)
```bash
curl -X POST http://localhost:9000/api/payments/courses/123/order \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

Expected:
```json
{
  "orderId": "order_xxx",
  "amount": 50000,
  "currency": "INR",
  "keyId": "rzp_live_xxx"
}
```

## 🔐 Switch to Test Mode

For testing without real money:

1. Update `backend/.env`:
```env
RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY
RAZORPAY_KEY_SECRET=YOUR_TEST_SECRET
```

2. Update `frontend/.env`:
```env
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY
```

3. Restart both backend and frontend

## 📱 Test on Real Device

### Android
```bash
cd frontend
flutter run -d <device-id>
```

### iOS
```bash
cd frontend
flutter run -d <device-id>
```

## ✨ Success Indicators

### Frontend
- ✅ Razorpay checkout opens smoothly
- ✅ Payment success shows green snackbar
- ✅ Navigates to "My Courses" automatically
- ✅ Course appears in enrolled list

### Backend
- ✅ Order creation logs appear
- ✅ Payment verification logs appear
- ✅ Enrollment logs appear
- ✅ Email sending logs appear

### Moodle
- ✅ User appears in course participants
- ✅ User can access course content

## 🎉 You're Done!

If all tests pass, your payment integration is working correctly!

## 📞 Need Help?

1. Check `PAYMENT_INTEGRATION.md` for detailed docs
2. Review backend logs for `[Payment]` entries
3. Verify all `.env` files have correct values
4. Test with Razorpay test mode first
