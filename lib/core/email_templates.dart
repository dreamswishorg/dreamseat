class EmailTemplates {
  static const String _logoUrl = 'https://trhefcuuhwavbdqhgamr.supabase.co/storage/v1/object/public/business_branding/logo_full.png';
  static const String _primaryColor = '#2E7D32';


  static String base(String content) => '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Plus Jakarta Sans', Arial, sans-serif; margin: 0; padding: 0; background-color: #f8fafc; color: #1e293b; }
        .container { max-width: 600px; margin: 20px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05); }
        .header { background-color: $_primaryColor; padding: 40px 20px; text-align: center; }
        .content { padding: 40px; line-height: 1.6; }
        .footer { background: #f1f5f9; padding: 30px; text-align: center; font-size: 12px; color: #64748b; }
        .button { display: inline-block; padding: 16px 32px; background-color: $_primaryColor; color: #ffffff !important; text-decoration: none; border-radius: 14px; font-weight: bold; margin-top: 25px; }
        .highlight { color: $_primaryColor; font-weight: bold; }
        .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 20px; margin: 20px 0; }
        h1 { font-size: 24px; font-weight: 800; margin: 0 0 15px 0; color: #0f172a; }
        p { margin: 0 0 15px 0; font-size: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="$_logoUrl" alt="DreamEats" height="40" style="margin-bottom: 10px;">
            <div style="color: #ffffff; font-weight: 800; font-size: 20px; letter-spacing: -0.5px;">DREAM<span style="opacity: 0.8">EATS</span></div>
        </div>
        <div class="content">
            $content
        </div>
        <div class="footer">
            <p><strong>DreamEats Ghana</strong><br>Saving meals, saving the planet 🌿</p>
            <p>Accra, Ghana • <a href="https://dreameatsgh.com" style="color: $_primaryColor; text-decoration: none;">Website</a></p>
            <p style="opacity: 0.6; margin-top: 20px;">© 2024 DreamEats. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';

  static String welcome(String name) => base('''
    <h1>Welcome to the Green Movement, $name! 🌿</h1>
    <p>We're thrilled to have you join DreamEats. You're now part of a community dedicated to reducing food waste while enjoying delicious meals at incredible prices.</p>
    <div class="card">
        <p><strong>What's next?</strong></p>
        <ul style="padding-left: 20px; margin: 0; font-size: 14px;">
            <li>Browse surplus deals from your favorite local spots.</li>
            <li>Rescue a meal and save up to 70%.</li>
            <li>Track your CO₂ impact in the app.</li>
        </ul>
    </div>
    <p>Ready to rescue your first meal?</p>
    <a href="https://dreameats.app" class="button">Explore Deals Nearby</a>
''');

  static String orderConfirmed({
    required String customerName,
    required String dealTitle,
    required String businessName,
    required String collectionCode,
    required String price,
    required String pickupWindow,
  }) => base('''
    <h1 style="color: $_primaryColor;">Order Confirmed! ✅</h1>
    <p>Hi $customerName, your rescue mission is successful! Your order from <strong>$businessName</strong> is reserved and ready for pickup soon.</p>

    <div class="card" style="border-left: 4px solid $_primaryColor;">
        <p style="margin-bottom: 8px;"><span style="color: #64748b; font-size: 12px; font-weight: bold; text-transform: uppercase;">Collection Code</span></p>
        <p style="font-size: 32px; font-weight: 800; color: $_primaryColor; margin: 0; letter-spacing: 2px;">$collectionCode</p>
    </div>

    <div class="card">
        <p><strong>Order Details:</strong></p>
        <p>Item: <span class="highlight">$dealTitle</span></p>
        <p>Pickup: <span class="highlight">$pickupWindow</span></p>
        <p>Total Paid: <span class="highlight">$price</span></p>
    </div>

    <p style="font-size: 13px; color: #64748b;"><strong>Note:</strong> Please show your collection code at the counter during the pickup window. The merchant will verify it to complete your rescue.</p>

    <a href="https://dreameats.app/orders" class="button">View My Rescue Ticket</a>
''');

  static String merchantNewOrder({
    required String merchantName,
    required String customerName,
    required String dealTitle,
    required String price,
    required String collectionCode,
  }) => base('''
    <h1>🛍️ New Order Received!</h1>
    <p>Hi $merchantName, a customer has just rescued a surplus meal from your shop.</p>

    <div class="card">
        <p><strong>Summary:</strong></p>
        <p>Customer: <strong>$customerName</strong></p>
        <p>Item: <strong>$dealTitle</strong></p>
        <p>Payout: <span class="highlight">$price</span></p>
    </div>

    <p>The customer will arrive during your specified pickup window and present their secret 4-digit collection code on their phone screen. Please ask for and enter their code in your Merchant Dashboard to verify pickup and trigger your payout.</p>
    <div style="background: #fff; border: 2px dashed #f59e0b; padding: 15px; text-align: center; border-radius: 12px; font-size: 18px; font-weight: 800; color: #d97706;">
        ⏳ AWAITING CUSTOMER PICKUP
    </div>

    <a href="https://dreameats.app/merchant" class="button">Open Merchant Dashboard</a>
''');

  static String passwordReset(String link) => base('''
    <h1>Reset Your Password 🔐</h1>
    <p>We received a request to reset your DreamEats password. No worries, it happens!</p>
    <p>Click the button below to choose a new password. This link will expire in 24 hours.</p>
    <a href="$link" class="button">Reset My Password</a>
    <p style="margin-top: 25px; font-size: 12px; color: #64748b;">If you didn't request this, you can safely ignore this email.</p>
''');

  static String emailConfirmation(String link) => base('''
    <h1>Confirm Your Email 📧</h1>
    <p>Thanks for signing up for DreamEats! Please verify your email address to activate your account and start rescuing meals.</p>
    <a href="$link" class="button">Confirm My Email</a>
    <p style="margin-top: 25px; font-size: 12px; color: #64748b;">If you didn't create an account, you can ignore this email.</p>
''');

  static String merchantApproved(String merchantName) => base('''
    <h1>Welcome Aboard, $merchantName! 🎉</h1>
    <p>Great news! Your merchant profile has been verified and approved by the DreamEats team.</p>
    <p>You can now start listing your surplus food and reaching hungry customers in Accra.</p>
    <div class="card">
        <p><strong>Merchant Checklist:</strong></p>
        <ul style="padding-left: 20px; margin: 0; font-size: 14px;">
            <li>Upload your shop logo and cover photo.</li>
            <li>List your first surplus "Rescue Pack".</li>
            <li>Set your pickup windows.</li>
        </ul>
    </div>
    <a href="https://dreameats.app/merchant" class="button">Go to Merchant Dashboard</a>
''');

  static String disputeResolved(String ticketId, String resolution) => base('''
    <h1>Dispute Resolved ✅</h1>
    <p>Your dispute (Ticket #$ticketId) has been reviewed and resolved by our support team.</p>
    <div class="card">
        <p><strong>Resolution:</strong></p>
        <p>$resolution</p>
    </div>
    <p>Thank you for your patience as we work to keep DreamEats fair for everyone.</p>
    <a href="https://dreameats.app/support" class="button">View Ticket Details</a>
''');
}
