import 'package:flutter/material.dart';
import '../utils/dynamic_translator.dart';

class HomeScreen extends StatefulWidget {
  final String businessName;

  const HomeScreen({
    super.key,
    this.businessName = 'Your Business Name',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Default selected item (Center Scanner Icon)

  // Helper method for dynamic translation
  Widget _buildTranslatedText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
  }) {
    return FutureBuilder<String>(
      future: DynamicTranslator.translate(text),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Top Header Header: Business Name
            Center(
              child: _buildTranslatedText(
                widget.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Flexible content area
            const Expanded(
              child: SizedBox(),
            ),

            // Bottom Navigation Container
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF14202E),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. User Profile Icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    icon: Icon(
                      Icons.account_circle_outlined,
                      size: 32,
                      color: _selectedIndex == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  // 2. Warehouse / Inventory Icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    icon: Icon(
                      Icons.home_work_outlined,
                      size: 30,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  // 3. Center Scanner Floating Action Circular Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 30,
                          color: const Color(0xFF030D19),
                        ),
                      ),
                    ),
                  ),

                  // 4. Discount / Shopping Bag Icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    icon: Icon(
                      Icons.local_offer_outlined,
                      size: 28,
                      color: _selectedIndex == 3
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  // 5. POS Terminal Card Machine Icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                    icon: Icon(
                      Icons.point_of_sale_rounded,
                      size: 28,
                      color: _selectedIndex == 4
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
