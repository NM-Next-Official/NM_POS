import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/scanner_cart_icon.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? businessName;

  const HomeScreen({super.key, this.businessName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    final displayName = widget.businessName ??
        auth.user?.businessName ??
        auth.user?.displayName ??
        'Your Business Name';

    return Scaffold(
      backgroundColor: const Color(0xFF030D19),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header (only when NOT on profile) ───
            if (_selectedIndex != 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // ─── Body ───
            Expanded(
              child: _buildBody(t),
            ),

            // ─── Bottom Nav ───
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF14202E),
                borderRadius: BorderRadius.circular(38),
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
                  // 1. Profile
                  _NavIcon(
                    tooltip: t.profile,
                    icon: Icons.account_circle_outlined,
                    isActive: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),

                  // 2. Inventory
                  _NavIcon(
                    tooltip: t.inventory,
                    icon: Icons.home_work_outlined,
                    isActive: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),

                  // 3. Center — Scanner
                  _CenterScannerButton(
                    isActive: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),

                  // 4. Discounts
                  _DiscountIcon(
                    isActive: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),

                  // 5. POS
                  _NavIcon(
                    tooltip: t.pos,
                    icon: Icons.point_of_sale_rounded,
                    isActive: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    switch (_selectedIndex) {
      case 0:
        return const ProfileScreen();   // ← Full profile with logout

      case 1:
        return const _PlaceholderView(
          icon: Icons.home_work_outlined,
          label: 'Inventory',
        );

      case 2:
        return const _PlaceholderView(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scanner',
        );

      case 3:
        return const _PlaceholderView(
          icon: Icons.local_offer_outlined,
          label: 'Discounts',
        );

      case 4:
        return const _PlaceholderView(
          icon: Icons.point_of_sale_rounded,
          label: 'POS',
        );

      default:
        return const SizedBox();
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Placeholder for future screens
// ──────────────────────────────────────────────────────────────
class _PlaceholderView extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceholderView({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coming soon',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Nav icon (simple)
// ──────────────────────────────────────────────────────────────
class _NavIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 30,
          color: isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Center button — Scanner + Cart
// ──────────────────────────────────────────────────────────────
class _CenterScannerButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterScannerButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFFCBD5E1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: const Center(
          child: ScannerCartIcon(size: 32),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Discount icon — bag with % badge
// ──────────────────────────────────────────────────────────────
class _DiscountIcon extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _DiscountIcon({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? Colors.white : Colors.white.withValues(alpha: 0.75);

    return IconButton(
      tooltip: 'Discounts',
      onPressed: onTap,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 28,
                color: color,
              ),
              Positioned(
                bottom: 4,
                right: 6,
                child: Text(
                  '%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}