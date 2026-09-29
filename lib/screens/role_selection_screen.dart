import 'package:flutter/material.dart';

import '../languages/app_localizations.dart';
import '../models/user_role.dart';
import '../widgets/auth/auth_scaffold.dart';
import 'signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AuthScaffold(
      title: t.chooseAccountType,
      showBackButton: true,
      showLogo: true,
      dense: true,
      logoSize: 160,
      child: Column(
        children: [
          _RoleCard(
            icon: Icons.storefront_rounded,
            title: t.businessOwner,
            description: t.businessOwnerDesc,
            onTap: () => _pick(context, UserRole.owner),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.person_outline_rounded,
            title: t.personalBusiness,
            description: t.personalBusinessDesc,
            onTap: () => _pick(context, UserRole.basic),
          ),
        ],
      ),
    );
  }

  void _pick(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpScreen(role: role),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF14202E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5ECF4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF030D19), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}