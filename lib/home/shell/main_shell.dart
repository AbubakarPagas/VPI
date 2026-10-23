/// VPI Secure — Main Shell.
///
/// The authenticated root widget that hosts the four bottom-navigation tabs:
///   0 · Home      → VpiDashboardScreen
///   1 · Devices   → DevicesScreen
///   2 · Alerts    → AlertsScreen
///   3 · Profile   → ProfileScreen
///
/// Design decisions:
///   • [IndexedStack] preserves each tab's scroll position and state when
///     switching, avoiding expensive rebuilds and lost scroll offsets.
///   • The [NavigationBar] is styled entirely through [AppTheme._navigationBarTheme]
///     — no inline overrides needed here.
///   • A hairline top border + upward glow separate the bar from the content.
///   • The Alerts tab shows a live unread-count badge driven by [_unreadCount].
///     Increment / clear hooks will be wired in a future stage.
///   • The bell in [DashboardAppBar] calls [switchToAlerts] instead of
///     navigating to a new route, keeping the tab state intact.
///   • [PageController] is intentionally NOT used — tab switches are instant
///     (no swipe gesture). This matches iOS Settings / Twitter-style nav.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../alerts/alerts_screen.dart';
import '../devices/devices_screen.dart';
import '../profile/profile_screen.dart';
import '../vpi_dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainShell
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final User user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Placeholder unread count — will be driven by a real stream in a
  // future stage. Kept here so the badge is live-updatable without a
  // structural change.
  int _unreadCount = 0;

  // ── Tab switching ─────────────────────────────────────────────────────────

  /// Public API used by [VpiDashboardScreen] (bell tap) to jump to Alerts.
  void switchToAlerts() {
    if (_selectedIndex != 2) {
      setState(() => _selectedIndex = 2);
      HapticFeedback.selectionClick();
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return; // no-op on same tab
    setState(() => _selectedIndex = index);
    HapticFeedback.selectionClick();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      // IndexedStack keeps every tab alive — no rebuilds or scroll-position
      // loss on tab switches.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 0 — Home
          VpiDashboardScreen(
            user: widget.user,
            onBellTap: switchToAlerts,
          ),
          // Tab 1 — Devices
          const DevicesScreen(),
          // Tab 2 — Alerts
          AlertsScreen(
            unreadCount: _unreadCount,
            isTab: true,
          ),
          // Tab 3 — Profile
          ProfileScreen(
            user: widget.user,
            isTab: true,
          ),
        ],
      ),
      bottomNavigationBar: _NavBar(
        selectedIndex: _selectedIndex,
        unreadCount: _unreadCount,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBar
// ─────────────────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onDestinationSelected;

  const _NavBar({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Hairline top separator ─────────────────────────────────────────
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.blueGlow20,
                AppColors.divider,
                AppColors.blueGlow20,
                Colors.transparent,
              ],
              stops: const [0.0, 0.1, 0.5, 0.9, 1.0],
            ),
          ),
        ),

        // ── Navigation bar ────────────────────────────────────────────────
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            // 0 — Home
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // 1 — Devices
            const NavigationDestination(
              icon: Icon(Icons.devices_outlined),
              selectedIcon: Icon(Icons.devices_rounded),
              label: 'Devices',
            ),
            // 2 — Alerts (with badge)
            NavigationDestination(
              icon: _AlertIcon(
                unreadCount: unreadCount,
                isSelected: selectedIndex == 2,
              ),
              selectedIcon: _AlertIcon(
                unreadCount: unreadCount,
                isSelected: true,
              ),
              label: 'Alerts',
            ),
            // 3 — Profile
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AlertIcon — bell icon with a live red badge dot.
//
// Uses Material 3's [Badge] widget so the badge renders outside the icon's
// own bounds without needing Stack + Clip.none hacks.
// ─────────────────────────────────────────────────────────────────────────────

class _AlertIcon extends StatelessWidget {
  final int unreadCount;
  final bool isSelected;

  const _AlertIcon({required this.unreadCount, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryBright : AppColors.textMuted;
    final iconData = isSelected
        ? Icons.notifications_rounded
        : Icons.notifications_none_rounded;

    if (unreadCount == 0) {
      return Icon(iconData, color: color);
    }

    final label = unreadCount > 9 ? '9+' : '$unreadCount';

    return Badge(
      backgroundColor: AppColors.danger,
      textColor: Colors.white,
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Icon(iconData, color: color),
    );
  }
}
