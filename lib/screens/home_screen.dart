import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'scanner_pos_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? businessName;
  const HomeScreen({super.key, this.businessName});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const _items = [
    _NavItem('Overview', 'Home', Icons.space_dashboard_outlined),
    _NavItem('Inventory', 'Stock', Icons.inventory_2_outlined),
    _NavItem('Point of sale', 'POS', Icons.point_of_sale_outlined),
    _NavItem('Devices', 'Devices', Icons.devices_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final businessName = widget.businessName ?? user?.businessName ?? 'NM POS';
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : 'Account';
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Row(children: [
          if (wide) _sideNavigation(businessName),
          Expanded(
            child: Column(children: [
              _topBar(businessName, displayName, user),
              Expanded(child: _screen()),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                      icon: Icon(item.icon), label: item.shortLabel),
              ],
            ),
    );
  }

  Widget _sideNavigation(String businessName) => Container(
        width: 220,
        decoration: const BoxDecoration(
          color: Color(0xFF06111E),
          border: Border(right: BorderSide(color: Color(0xFF172738))),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
            child: Row(children: [
              Image.asset('assets/logo.png',
                  width: 42, height: 42, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('NM POS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                    Text(businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9AABBB), fontSize: 11)),
                  ])),
            ]),
          ),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: _NavButton(
                  item: _items[i],
                  selected: _selectedIndex == i,
                  onTap: () => setState(() => _selectedIndex = i)),
            ),
          const Spacer(),
          const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Inventory · Sales · Reports',
                  style: TextStyle(color: Color(0xFF718396), fontSize: 11))),
        ]),
      );

  Widget _topBar(String businessName, String displayName, AppUser? user) =>
      Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
            color: Color(0xFF06111E),
            border: Border(bottom: BorderSide(color: Color(0xFF172738)))),
        child: Row(children: [
          if (MediaQuery.sizeOf(context).width < 760) ...[
            Image.asset('assets/logo.png',
                width: 34, height: 34, fit: BoxFit.contain),
            const SizedBox(width: 8),
          ],
          Expanded(
              child: Text(businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16))),
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Scaffold(
                            backgroundColor: Color(0xFF030D19),
                            body: SafeArea(
                                child: ProfileScreen(initialUser: user)))));
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'))),
              PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                      leading: Icon(Icons.logout), title: Text('Sign out'))),
            ],
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE4EAF2),
                backgroundImage: user?.profileImageData == null
                    ? null
                    : MemoryImage(user!.profileImageData!),
                child: user?.profileImageData == null
                    ? const Icon(Icons.person,
                        size: 19, color: Color(0xFF182535))
                    : null,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFE4EAF2),
                          fontWeight: FontWeight.w600))),
              const Icon(Icons.expand_more, color: Color(0xFF9AABBB)),
            ]),
          ),
        ]),
      );

  Widget _screen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
            onSell: () => setState(() => _selectedIndex = 2),
            onInventory: () => setState(() => _selectedIndex = 1));
      case 1:
        return const InventoryScreen();
      case 2:
        return const ScannerPosScreen();
      case 3:
        return const DevicesScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.shortLabel, this.icon);
  final String label, shortLabel;
  final IconData icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFF16283A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              child: Row(children: [
                Icon(item.icon,
                    size: 20,
                    color: selected
                        ? const Color(0xFFE4EAF2)
                        : const Color(0xFF8092A5)),
                const SizedBox(width: 12),
                Text(item.label,
                    style: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF9AABBB),
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600)),
              ])),
        ),
      );
}
