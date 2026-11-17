import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../languages/app_localizations.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/auth/user_profile_repository.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.initialUser});

  final AppUser? initialUser;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = UserProfileRepository();
  bool _savingPhoto = false;

  Future<void> _changePhoto(AppUser user) async {
    if (_savingPhoto) return;
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (!mounted || result.isEmpty) return;

    final pickedFile = result.first;
    final reportedSize = pickedFile.lengthSync();
    if (reportedSize != null && reportedSize > 20 * 1024 * 1024) {
      _showMessage('Choose an image smaller than 20 MB.');
      return;
    }
    final source = await pickedFile.readAsBytes();
    if (!mounted) return;
    if (source == null || source.isEmpty) {
      _showMessage('Could not read that image. Choose another photo.');
      return;
    }
    if (source.length > 20 * 1024 * 1024) {
      _showMessage('Choose an image smaller than 20 MB.');
      return;
    }

    setState(() => _savingPhoto = true);
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) throw const FormatException('Unsupported image');
      final oriented = img.bakeOrientation(decoded);
      final resized = oriented.width >= oriented.height
          ? img.copyResize(oriented, width: 512)
          : img.copyResize(oriented, height: 512);
      final compressed =
          Uint8List.fromList(img.encodeJpg(resized, quality: 82));
      await _profileRepository.saveProfilePhoto(
        userId: user.id,
        imageBytes: compressed,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(
            user.copyWith(profileImageData: compressed),
          );
      _showMessage('Profile photo updated.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not save the photo. Run the profile image SQL in pgAdmin, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? widget.initialUser;

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.account_circle_outlined,
                size: 48, color: Color(0xFF9AABBB)),
            const SizedBox(height: 12),
            const Text('Profile details are unavailable.',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: auth.isBusy ? null : auth.bootstrap,
              icon: auth.isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: const Text('Reload profile'),
            ),
          ]),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('My profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                const Text('Your account and business information',
                    style: TextStyle(color: Color(0xFF91A1B1), fontSize: 13)),
                const SizedBox(height: 22),
                _ProfileHero(
                  user: user,
                  savingPhoto: _savingPhoto,
                  onChangePhoto: () => _changePhoto(user),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Contact information',
                  icon: Icons.contact_mail_outlined,
                  rows: [
                    if (user.email?.isNotEmpty == true)
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email address',
                          value: user.email!),
                    if (user.phone?.isNotEmpty == true)
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone number',
                          value: user.phone!),
                    if (user.email?.isEmpty != false &&
                        user.phone?.isEmpty != false)
                      const _InfoRow(
                          icon: Icons.info_outline,
                          label: 'Contact',
                          value: 'No contact details added'),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Business information',
                  icon: Icons.storefront_outlined,
                  rows: [
                    if (user.businessName?.isNotEmpty == true)
                      _InfoRow(
                          icon: Icons.storefront_outlined,
                          label: 'Business name',
                          value: user.businessName!),
                    if (user.businessAddress?.isNotEmpty == true)
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Business address',
                          value: user.businessAddress!),
                    if (user.businessName?.isEmpty != false &&
                        user.businessAddress?.isEmpty != false)
                      const _InfoRow(
                          icon: Icons.info_outline,
                          label: 'Business',
                          value: 'No business details added'),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Account details',
                  icon: Icons.verified_user_outlined,
                  rows: [
                    _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Account type',
                        value: _roleLabel(user.role.name)),
                    _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: _formatDate(user.createdAt)),
                    _InfoRow(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Assigned outlets',
                        value: user.outletIds.isEmpty
                            ? 'Not assigned'
                            : '${user.outletIds.length} ${user.outletIds.length == 1 ? 'outlet' : 'outlets'}'),
                    _InfoRow(
                        icon: Icons.fingerprint,
                        label: 'Account ID',
                        value: user.id),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, t),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A8A),
                      side: const BorderSide(color: Color(0x664C272D)),
                      backgroundColor: const Color(0xFF25171D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(t.logout,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppLocalizations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF14202E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.logout,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Color(0xFFB0BEC5))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Log out',
                  style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'owner':
        return 'Business owner';
      case 'salesman':
        return 'Salesperson';
      default:
        return 'Standard account';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.savingPhoto,
    required this.onChangePhoto,
  });
  final AppUser user;
  final bool savingPhoto;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF13263A), Color(0xFF0D1A29)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF283B50)),
        ),
        child: Column(children: [
          Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFDFE7F0)),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFDFE7F0),
                backgroundImage: user.profileImageData == null
                    ? null
                    : MemoryImage(user.profileImageData!),
                child: user.profileImageData == null
                    ? Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF06111E),
                            fontSize: 42,
                            fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
            ),
            Material(
              color: const Color(0xFFE4EAF2),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: savingPhoto ? null : onChangePhoto,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: savingPhoto
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF06111E)),
                          )
                        : const Icon(Icons.camera_alt_outlined,
                            size: 18, color: Color(0xFF06111E)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 15),
          Text(user.displayName.isEmpty ? 'NM POS user' : user.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFF1A302B),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF326849))),
            child: Text(
              user.role.name.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF84D49A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 9),
          const Text('Tap the camera to add or update your photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9AABBB), fontSize: 12)),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.rows});
  final String title;
  final IconData icon;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A29),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF223548)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFFB4C3D1)),
            const SizedBox(width: 9),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          ...rows,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: const Color(0xFF9AABBB)),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF8194A8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              SelectableText(value,
                  style: const TextStyle(
                      color: Color(0xFFE4EAF2),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      );
}
