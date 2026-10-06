import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/config.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Future<void> _launchWebVersion(BuildContext context) async {
    final uri = Uri.parse(AppConfig.termsOfServiceUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not open $uri in browser"),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening browser: $e"),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppTheme.lightGreenBg;
    final textColor = isDark ? Colors.white : AppTheme.charcoal;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            color: AppTheme.primaryGreen,
            tooltip: "Open in Browser",
            onPressed: () => _launchWebVersion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppTheme.primaryGreen, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DreamEats Ghana Terms",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Last updated: October 2026",
                          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildSection(
              "1. Introduction & Acceptance",
              "Welcome to DreamEats Ghana. By accessing or using our mobile application and surplus food marketplace, you agree to be bound by these Terms of Service. If you do not agree to all terms, please discontinue use immediately.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "2. Surplus Food Marketplace Nature",
              "DreamEats connects consumers with local restaurants, bakeries, hotels, and grocery stores offering fresh surplus food at discounted rates. Meals are prepared safely by food merchants according to Ghana Food and Drugs Authority (FDA) regulations. While merchants guarantee quality during pickup windows, exact contents of surprise or mystery bags may vary depending on daily surplus.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "3. Orders, Pickup Windows & Redemptions",
              "When you reserve a surplus pack on DreamEats, you must collect your order during the merchant's specified pickup window. Upon arrival, present your digital collection order or receipt. Orders not picked up within the designated timeframe cannot be refunded, as merchants hold perishable food specifically for your reservation.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "4. Pricing, Payments & Refunds",
              "All prices are listed in Ghanaian Cedis (GHS) and include applicable discounts. Payments are securely processed via mobile money (MTN MoMo, Telecel, AirtelTigo) or credit/debit card. Refunds are granted if a store is closed during the pickup window or if an order is cancelled by the merchant prior to pickup.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "5. DreamPoints & Loyalty Program",
              "DreamPoints are reward tokens earned through surplus food rescues and referral milestones. Points have no cash surrender value and can only be redeemed within DreamEats for discount vouchers, free bakery packs, or special promotional listings.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "6. User Conduct & Prohibited Activities",
              "Users agree to interact respectfully with store personnel during pickups. Fraudulent claims, unauthorized redistribution of surplus codes, or abuse of the review and support ticketing system may result in immediate account suspension.",
              textColor,
              subtextColor,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.language_rounded, size: 18),
                label: const Text("View Hosted Document at dreameatsgh.com"),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _launchWebVersion(context),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body, Color titleColor, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: titleColor, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: bodyColor, height: 1.6)),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchWebVersion(BuildContext context) async {
    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not open $uri in browser"),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening browser: $e"),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final textColor = isDark ? Colors.white : AppTheme.charcoal;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            color: Colors.blue,
            tooltip: "Open in Browser",
            onPressed: () => _launchWebVersion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Data Protection",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Compliant with Ghana Data Protection Act (Act 843)",
                          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildSection(
              "1. Information We Collect",
              "We collect personal information necessary to provide food rescue services, including your full name, email address, phone number, delivery/pickup location preferences, and order history. We also collect geolocation signals when authorized to show nearby partner vendors.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "2. How We Use Your Location",
              "DreamEats requests precise and approximate location data to sort nearby surplus food deals by distance (in kilometers) and provide accurate navigation instructions to partner storefronts. Location data is only accessed when authorized and is never sold to third-party data brokers.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "3. Payment & Security",
              "Mobile Money and payment transaction processing are encrypted via secure payment gateways (Paystack). DreamEats does not store your private banking PINs or raw credit card security numbers on our local databases.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "4. Sharing with Food Merchants",
              "When you place an order, your first name and order collection code are shared with the respective food merchant solely to facilitate accurate identity verification during food pickup.",
              textColor,
              subtextColor,
            ),
            _buildSection(
              "5. Data Deletion & Account Control (App Store 5.1.1v)",
              "You retain absolute control over your profile data. You can edit your personal details anytime under Profile Settings or permanently delete your account and all associated records directly in the app under Settings > Privacy & Security > Delete Account.",
              textColor,
              subtextColor,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.language_rounded, size: 18),
                label: const Text("View Hosted Document at dreameatsgh.com"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _launchWebVersion(context),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body, Color titleColor, Color bodyColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: titleColor, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: bodyColor, height: 1.6)),
        ],
      ),
    );
  }
}
