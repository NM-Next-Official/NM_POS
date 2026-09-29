import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // ── Avatar ──
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5ECF4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5ECF4).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF030D19),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Name ──
            Text(
              user.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 6),

            // ── Role badge ──
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _roleColor(user.role.name).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _roleColor(user.role.name).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _roleLabel(user.role.name),
                  style: TextStyle(
                    color: _roleColor(user.role.name),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Info card ──
            _InfoCard(
              children: [
                if (user.email != null && user.email!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email!,
                  ),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phone!,
                  ),
                if (user.businessName != null &&
                    user.businessName!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.storefront_outlined,
                    label: 'Business',
                    value: user.businessName!,
                  ),
                if (user.businessAddress != null &&
                    user.businessAddress!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: user.businessAddress!,
                  ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: _formatDate(user.createdAt),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ── LOGOUT BUTTON ──
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context, t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A1F23),
                  foregroundColor: const Color(0xFFE57373),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                    side: const BorderSide(
                      color: Color(0x33E57373),
                      width: 1.2,
                    ),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  t.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AppLocalizations t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF14202E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          t.logout,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Color(0xFFB0BEC5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFE57373),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFFFA726);
      case 'owner':
        return const Color(0xFF4CAF50);
      case 'salesman':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'ADMIN';
      case 'owner':
        return 'BUSINESS OWNER';
      case 'salesman':
        return 'SALESMAN';
      default:
        return 'BUSINESS';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14202E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB0BEC5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}