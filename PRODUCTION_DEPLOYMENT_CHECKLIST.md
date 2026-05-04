# Production Deployment Checklist

## 🔐 Security & Configuration

### Backend Configuration
- [ ] Verify `RAZORPAY_KEY_ID` is set to **live** key (starts with `rzp_live_`)
- [ ] Verify `RAZORPAY_KEY_SECRET` is set to **live** secret
- [ ] Ensure `.env` file is **NOT** committed to version control
- [ ] Verify `.gitignore` includes `.env`
- [ ] Set `NODE_ENV=production` in production environment
- [ ] Configure proper `CORS_ORIGIN` (not `*` in production)
- [ ] Verify JWT secret is strong and unique
- [ ] Enable HTTPS for production API

### Frontend Configuration
- [ ] Verify `NEXT_PUBLIC_RAZORPAY_KEY_ID` is set to **live** key
- [ ] Set `APP_ENV=prod` in production `.env`
- [ ] Configure production API URLs
- [ ] Verify `.env` file is **NOT** committed to version control
- [ ] Build release version of app

## 🧪 Testing

### Pre-Production Testing
- [ ] Test free course enrollment
- [ ] Test paid course enrollment with test cards
- [ ] Test payment failure scenarios
- [ ] Test already enrolled scenario
- [ ] Verify email notifications work
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Verify web shows appropriate message

### Production Testing (with real money)
- [ ] Create a test course with minimal price (₹1)
- [ ] Complete end-to-end payment with real card
- [ ] Verify enrollment in Moodle
- [ ] Verify email received
- [ ] Verify notification received
- [ ] Check payment appears in Razorpay dashboard
- [ ] Verify backend logs are correct

## 📊 Monitoring & Logging

### Backend Logging
- [ ] Verify payment logs are being written
- [ ] Set up log aggregation (e.g., CloudWatch, Papertrail)
- [ ] Configure error alerting
- [ ] Monitor payment success/failure rates

### Razorpay Dashboard
- [ ] Set up webhook for payment status updates (optional)
- [ ] Configure email notifications for payments
- [ ] Set up payment reconciliation process
- [ ] Monitor transaction reports

## 🔔 Notifications

### Email Configuration
- [ ] Verify SMTP settings are correct
- [ ] Test enrollment confirmation emails
- [ ] Verify email templates are professional
- [ ] Check spam folder to ensure deliverability
- [ ] Configure SPF/DKIM records for email domain

### Push Notifications
- [ ] Verify Socket.IO connection works
- [ ] Test real-time notifications
- [ ] Verify notification persistence

## 📱 Mobile App

### Android
- [ ] Build release APK/AAB
- [ ] Test on multiple Android versions
- [ ] Verify Proguard rules don't break Razorpay
- [ ] Test payment flow on release build
- [ ] Upload to Play Store (if applicable)

### iOS
- [ ] Build release IPA
- [ ] Test on multiple iOS versions
- [ ] Verify payment flow on release build
- [ ] Upload to App Store (if applicable)

## 🗄️ Database & Moodle

### Moodle Integration
- [ ] Verify Moodle API tokens are valid
- [ ] Test enrollment API works
- [ ] Verify course data syncs correctly
- [ ] Check user data mapping
- [ ] Test with multiple courses

## 💰 Payment Configuration

### Razorpay Settings
- [ ] Verify business details in Razorpay dashboard
- [ ] Configure payment methods (cards, UPI, wallets)
- [ ] Set up auto-capture or manual capture
- [ ] Configure refund policy
- [ ] Set up settlement schedule
- [ ] Verify bank account for settlements

### Pricing
- [ ] Verify all course prices are correct
- [ ] Test with different price points
- [ ] Verify currency is set to INR
- [ ] Check for any pricing edge cases

## 🚨 Error Handling

### Backend Error Handling
- [ ] Verify all errors are logged
- [ ] Test error responses are user-friendly
- [ ] Verify payment failures are handled gracefully
- [ ] Test network timeout scenarios
- [ ] Verify duplicate payment prevention

### Frontend Error Handling
- [ ] Test network error scenarios
- [ ] Verify error messages are user-friendly
- [ ] Test payment cancellation flow
- [ ] Verify retry mechanism works

## 📖 Documentation

### Internal Documentation
- [ ] Document payment flow for team
- [ ] Create runbook for payment issues
- [ ] Document refund process
- [ ] Create troubleshooting guide
- [ ] Document Razorpay credentials location

### User Documentation
- [ ] Create FAQ for payment issues
- [ ] Document supported payment methods
- [ ] Create refund policy document
- [ ] Document customer support process

## 🔄 Backup & Recovery

### Data Backup
- [ ] Verify Moodle backups are working
- [ ] Document payment reconciliation process
- [ ] Set up payment logs backup
- [ ] Create disaster recovery plan

### Rollback Plan
- [ ] Document rollback procedure
- [ ] Keep previous version deployable
- [ ] Test rollback process
- [ ] Document known issues and fixes

## 📞 Support

### Customer Support
- [ ] Set up support email/phone
- [ ] Create payment issue escalation process
- [ ] Train support team on payment flow
- [ ] Create support ticket system
- [ ] Document common payment issues

### Technical Support
- [ ] Set up on-call rotation
- [ ] Create incident response plan
- [ ] Document Razorpay support contacts
- [ ] Set up monitoring alerts

## 🎯 Performance

### Backend Performance
- [ ] Load test payment endpoints
- [ ] Verify response times are acceptable
- [ ] Monitor server resources
- [ ] Set up auto-scaling (if applicable)

### Frontend Performance
- [ ] Test app performance on low-end devices
- [ ] Verify payment flow is smooth
- [ ] Check for memory leaks
- [ ] Optimize image loading

## 🔍 Compliance

### Legal & Compliance
- [ ] Verify PCI DSS compliance (Razorpay handles this)
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Document data retention policy
- [ ] Verify GDPR compliance (if applicable)

### Financial Compliance
- [ ] Verify GST/tax configuration
- [ ] Set up invoice generation
- [ ] Document accounting process
- [ ] Verify payment gateway compliance

## 📈 Analytics

### Payment Analytics
- [ ] Set up payment success rate tracking
- [ ] Monitor average transaction value
- [ ] Track payment method preferences
- [ ] Monitor refund rates
- [ ] Set up conversion funnel tracking

### Business Metrics
- [ ] Track course enrollment rates
- [ ] Monitor revenue per course
- [ ] Track user acquisition cost
- [ ] Monitor customer lifetime value

## 🚀 Launch

### Pre-Launch
- [ ] Complete all checklist items
- [ ] Perform final end-to-end test
- [ ] Verify all team members are ready
- [ ] Schedule launch time
- [ ] Prepare rollback plan

### Launch Day
- [ ] Deploy backend to production
- [ ] Deploy frontend to production
- [ ] Monitor logs closely
- [ ] Test first payment immediately
- [ ] Monitor error rates
- [ ] Be ready for quick fixes

### Post-Launch
- [ ] Monitor for 24 hours continuously
- [ ] Check payment success rates
- [ ] Verify enrollments are working
- [ ] Monitor user feedback
- [ ] Address any issues immediately

## ✅ Sign-Off

### Technical Sign-Off
- [ ] Backend developer approval
- [ ] Frontend developer approval
- [ ] QA team approval
- [ ] DevOps team approval

### Business Sign-Off
- [ ] Product manager approval
- [ ] Finance team approval
- [ ] Legal team approval
- [ ] Management approval

## 📝 Post-Deployment

### Week 1
- [ ] Monitor payment success rates daily
- [ ] Review error logs daily
- [ ] Check customer feedback
- [ ] Address any issues
- [ ] Document lessons learned

### Month 1
- [ ] Review payment analytics
- [ ] Optimize based on data
- [ ] Plan improvements
- [ ] Update documentation
- [ ] Train additional team members

## 🎉 Success Criteria

- [ ] Payment success rate > 95%
- [ ] Average payment time < 2 minutes
- [ ] Zero critical bugs
- [ ] Positive user feedback
- [ ] Smooth enrollment process
- [ ] Email notifications working 100%
- [ ] No payment disputes
- [ ] Clean audit logs

---

## Notes

- This checklist should be reviewed and updated regularly
- All items should be checked before production deployment
- Keep a copy of this checklist for each deployment
- Document any deviations from the checklist
- Update checklist based on lessons learned

## Emergency Contacts

- **Razorpay Support**: support@razorpay.com
- **Technical Lead**: [Add contact]
- **DevOps Team**: [Add contact]
- **On-Call Engineer**: [Add contact]

## Useful Links

- Razorpay Dashboard: https://dashboard.razorpay.com
- Razorpay Docs: https://razorpay.com/docs
- Backend Logs: [Add link]
- Monitoring Dashboard: [Add link]
