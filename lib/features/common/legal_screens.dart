import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TERMS OF SERVICE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

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
            const SnackBar(content: Text("Could not open web link"), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: borderColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.4),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: AppTheme.primaryGreen,
            tooltip: "Open Hosted Version",
            onPressed: () => _launchWebVersion(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            color: primaryText,
            tooltip: "Copy Link",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: AppConfig.termsOfServiceUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Terms of Service link copied to clipboard!"), backgroundColor: AppTheme.primaryGreen),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Executive Header Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGreen),
                                SizedBox(width: 6),
                                Text(
                                  "OFFICIAL LEGAL AGREEMENT",
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, letterSpacing: 0.6),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Updated October 2026",
                            style: TextStyle(fontSize: 12, color: secondaryText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "DreamEats Marketplace Terms",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryText, letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please read these terms carefully before creating an account or reserving surplus food bags on DreamEats.",
                        style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      // Key Takeaways Highlight Box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F2B1D) : const Color(0xFFF1F8F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Summary Highlights",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryGreen),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "1. Meals must be collected within the designated store pickup window.\n"
                                    "2. All payments are secured in Ghanaian Cedis (GHS) via Ghana MoMo & Cards.\n"
                                    "3. Food quality adheres to Ghana Food & Drugs Authority (FDA) standards.",
                                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : const Color(0xFF064E3B), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Cards
                _buildLegalCard(
                  number: "01",
                  title: "Acceptance & Platform Role",
                  body: "By creating an account or using DreamEats, you form a legally binding agreement under the laws of Ghana. DreamEats operates as a technology marketplace connecting consumers with licensed restaurants, bakeries, hotels, and grocery vendors offering quality surplus food at discounted rates.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "02",
                  title: "Nature of Surplus Food & Mystery Packs",
                  body: "Merchants prepare and package surplus meals that are delicious and safe for consumption but would otherwise go to waste. Because packages reflect daily kitchen surpluses, exact items in 'Surprise Bags' vary. Merchants are bound to uphold Ghana Food & Drugs Authority (FDA) food safety standards.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "03",
                  title: "Pickup Windows & Order Redemptions",
                  body: "Each order includes a designated pickup window (e.g., 18:00 – 19:30). Customers must arrive during this window and present their in-app QR code or order number. Uncollected orders cannot be refunded because merchants hold perishable items specifically for the reserved slot.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "04",
                  title: "Pricing, Mobile Money & Refund Policy",
                  body: "Prices are quoted in Ghanaian Cedis (GHS) and include all platform discounts. Payments are securely processed via MTN MoMo, Telecel Cash, AT Money, and bank cards through PCI-DSS certified gateways (Paystack). Full refunds are provided if a partner merchant is closed during the pickup window or cancels the listing before pickup.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "05",
                  title: "DreamPoints, Rewards & Referrals",
                  body: "DreamPoints earned from food rescues and referral bonuses carry no cash surrender value and cannot be transferred outside the application. Points may be redeemed for meal discounts, free partner bags, and platform vouchers.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "06",
                  title: "Prohibited Actions & Account Termination",
                  body: "Users may not resell collected meals, duplicate QR redemption codes, harass store personnel, or abuse promotional credits. DreamEats reserves the right to suspend accounts engaged in fraudulent or abusive behavior immediately.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "07",
                  title: "Governing Law & Jurisdiction",
                  body: "These Terms are governed by and construed under the laws of the Republic of Ghana, including the Electronic Transactions Act, 2008 (Act 772). Any unresolved dispute shall be submitted to the courts of Accra, Ghana.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                const SizedBox(height: 12),

                // Team Contact & Legal Inquiries Card
                _buildLegalContactCard(context, isDark, borderColor, primaryText, secondaryText),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVACY POLICY SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

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
            const SnackBar(content: Text("Could not open web link"), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: borderColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.4),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: Colors.blueAccent,
            tooltip: "Open Hosted Version",
            onPressed: () => _launchWebVersion(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            color: primaryText,
            tooltip: "Copy Link",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: AppConfig.privacyPolicyUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Privacy Policy link copied to clipboard!"), backgroundColor: Colors.blueAccent),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Executive Header Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_rounded, size: 14, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text(
                                  "DATA PROTECTION ASSURANCE",
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.6),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Compliant with Act 843",
                            style: TextStyle(fontSize: 12, color: secondaryText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "DreamEats Privacy Policy",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryText, letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We believe in transparency. Learn how we safeguard your personal details, location preferences, and mobile transactions.",
                        style: TextStyle(fontSize: 14.5, color: secondaryText, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      // Key Highlights Box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13233A) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Our Core Privacy Commitments",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2563EB)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "• We never sell your personal information or contact details to third parties.\n"
                                    "• Location signals are used only to show nearby surplus food deals.\n"
                                    "• You have total control to download or permanently delete your account anytime.",
                                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : const Color(0xFF1E3A8A), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Sections
                _buildLegalCard(
                  number: "01",
                  title: "Personal Information We Collect",
                  body: "We collect information you provide directly, such as your full name, email address, and phone number when registering. When ordering, we collect order selections and preferred pickup times. For merchant partners, we collect store registration names, business locations, and verification documents.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "02",
                  title: "How We Use Geolocation Data",
                  body: "With your permission, we use your device's approximate or precise GPS coordinates to rank available food deals by travel distance and help you locate the partner store. Geolocation signals are never tracked continuously in the background or shared with advertisers.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "03",
                  title: "Payment Security & Financial Tokens",
                  body: "Payments via Mobile Money (MTN, Telecel, AT) or payment cards are processed through PCI-DSS Level 1 certified partners (Paystack). DreamEats never stores your confidential MoMo PIN, bank passwords, or CVV codes on our servers.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "04",
                  title: "Information Shared with Food Merchants",
                  body: "When you reserve a meal pack, the respective food merchant receives only your first name and your unique collection code to confirm your pickup. Merchants do not receive your full email address or financial payment credentials.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "05",
                  title: "Account Control & Permanent Deletion (App Store 5.1.1)",
                  body: "You maintain complete ownership of your data. You can export your order history, modify your profile, or delete your account permanently directly within the app under Settings > Privacy > Delete Account. Upon deletion, all associated authentication records and personal profiles are purged immediately.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),
                _buildLegalCard(
                  number: "06",
                  title: "Ghana Data Protection Act (Act 843) Compliance",
                  body: "We strictly observe the principles of the Data Protection Act, 2012 (Act 843) of the Republic of Ghana, guaranteeing lawfulness of processing, data minimization, accuracy, purpose limitation, and robust security safeguards.",
                  isDark: isDark,
                  borderColor: borderColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                const SizedBox(height: 12),

                // Team Contact & Legal Inquiries Card
                _buildLegalContactCard(context, isDark, borderColor, primaryText, secondaryText),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED LEGAL COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _buildLegalCard({
  required String number,
  required String title,
  required String body,
  required bool isDark,
  required Color borderColor,
  required Color primaryText,
  required Color secondaryText,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2B1D) : const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: primaryText, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(fontSize: 14, color: secondaryText, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildLegalContactCard(
  BuildContext context,
  bool isDark,
  Color borderColor,
  Color primaryText,
  Color secondaryText,
) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.headset_mic_rounded, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Legal & Privacy Inquiries",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Reach out directly to our team with any legal or privacy questions.",
                    style: TextStyle(fontSize: 12.5, color: secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: Text(AppConfig.supportEmail),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryText,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final uri = Uri(scheme: 'mailto', path: AppConfig.supportEmail, query: 'subject=Legal%20Inquiry');
                await launchUrl(uri);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.phone_outlined, size: 16),
              label: const Text("+233 24 567 8901"),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryText,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: '+233245678901');
                await launchUrl(uri);
              },
            ),
          ],
        ),
      ],
    ),
  );
}
