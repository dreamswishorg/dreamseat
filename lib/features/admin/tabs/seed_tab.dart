import 'package:flutter/material.dart';
import '../../../services/seed_service.dart';

class TabSeed extends StatefulWidget {
  const TabSeed({super.key});
  @override
  State<TabSeed> createState() => _TabSeedState();
}

class _TabSeedState extends State<TabSeed> {
  bool _l = false;
  final _e = TextEditingController(text: 'merchant@sample.com');
  final _n = TextEditingController(text: 'Sample Partner');
  final _b = TextEditingController(text: 'Tasty Surplus');
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("System Seed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                TextField(controller: _n, decoration: const InputDecoration(labelText: "Name")),
                const SizedBox(height: 16),
                TextField(controller: _e, decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 16),
                TextField(controller: _b, decoration: const InputDecoration(labelText: "Business")),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _l
                      ? null
                      : () async {
                          setState(() => _l = true);
                          try {
                            await SeedService().seedMerchantWithDeals(
                              name: _n.text,
                              email: _e.text,
                              password: 'password123',
                              businessName: _b.text,
                              businessDescription: "Sample",
                              businessCategory: "Restaurant Meal",
                            );
                          } finally {
                            if (mounted) setState(() => _l = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_l ? "WAIT..." : "SEED DATA"),
                ),
              ],
            ),
          ),
        ),
      );
}
