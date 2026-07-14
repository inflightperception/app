import 'package:flutter/material.dart';
import 'package:perceptionv1/screens/home_screen.dart';
import 'package:perceptionv1/screens/analysis_screen.dart';
import 'package:perceptionv1/screens/settings_screen.dart';
import 'package:perceptionv1/screens/login_screen.dart';
import 'package:perceptionv1/services/auth_service.dart';
// ---------------------------------------------------------------------------
// NAV ITEM MODEL
// ---------------------------------------------------------------------------

enum NavSection { dashboard, flightHistory, analytics, settings }

class _NavItem {
  final NavSection section;
  final IconData icon;
  final String label;
  const _NavItem(this.section, this.icon, this.label);
}

const _navItems = [
  _NavItem(NavSection.dashboard, Icons.grid_view_rounded, 'Dashboard'),
  _NavItem(NavSection.flightHistory, Icons.history_rounded, 'Flight History'),
  _NavItem(NavSection.analytics, Icons.bar_chart_rounded, 'Analytics'),
  _NavItem(NavSection.settings, Icons.settings_outlined, 'Settings'),
];

// ---------------------------------------------------------------------------
// MAIN SHELL
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  /// When non-null the shell starts on the analysis result page
  /// (still highlights Dashboard in the nav).
  final OFPAnalysisData? analysisData;
  final Pilot? currentPilot;

  const MainShell({super.key, this.analysisData, this.currentPilot});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  NavSection _active = NavSection.dashboard;
  OFPAnalysisData? _analysisData;
  late final Pilot? _currentPilot;

  // mobile drawer key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  static const _darkBg = Color(0xFF0F1117);
  static const _accentColor = Color(0xFF3B6FD4);

  @override
  void initState() {
    super.initState();
    _analysisData = widget.analysisData;
    _currentPilot = widget.currentPilot ?? AuthService.currentPilot;
  }

  // Called by HomeScreen after a successful analysis
  void showAnalysis(OFPAnalysisData data) {
    setState(() {
      _analysisData = data;
      _active = NavSection.dashboard; // keeps Dashboard highlighted
    });
  }

  void _navigate(NavSection section) {
    setState(() {
      _active = section;
      _analysisData = null; // clear analysis when switching away
    });
    // close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ── current content widget ────────────────────────────────────────────────

  Widget _buildContent() {
    // If we have analysis results and we're on dashboard, show analysis
    if (_active == NavSection.dashboard && _analysisData != null) {
      return AnalysisScreen(key: ValueKey(_analysisData), data: _analysisData!);
    }

    switch (_active) {
      case NavSection.dashboard:
        return HomeScreen(onAnalysisReady: showAnalysis);
      case NavSection.flightHistory:
        return _PlaceholderScreen(
          icon: Icons.history_rounded,
          title: 'Flight History',
          subtitle: 'Your past OFP analyses will appear here.',
        );
      case NavSection.analytics:
        return _PlaceholderScreen(
          icon: Icons.bar_chart_rounded,
          title: 'Analytics',
          subtitle: 'Fleet-wide fuel analytics coming soon.',
        );
      case NavSection.settings:
        return const SettingsScreen();
    }
  }

  // ── sidebar widget ────────────────────────────────────────────────────────

  Widget _buildSidebar({bool compact = false}) {
    return Container(
      width: compact ? 260 : double.infinity,
      color: _darkBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A84F0), Color(0xFF2A5CC0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.flight_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overflow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'FUEL INTELLIGENCE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _navItems.map((item) {
                  final isActive = _active == item.section;
                  return _NavTile(
                    item: item,
                    isActive: isActive,
                    onTap: () => _navigate(item.section),
                  );
                }).toList(),
              ),
            ),

            // User info at bottom
            const Divider(color: Colors.white12, thickness: 1, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _accentColor,
                    child: Text(
                      _currentPilot?.initials ?? '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPilot?.displayName ?? 'Pilot',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _currentPilot?.email ?? 'Authenticated',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: Colors.white.withOpacity(0.65),
                      size: 18,
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

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;

    if (isMobile) {
      // Mobile: AppBar + Drawer
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: _buildAppBar(),
        drawer: Drawer(
          width: 260,
          backgroundColor: Colors.transparent,
          child: _buildSidebar(),
        ),
        body: _buildContent(),
      );
    }

    // Desktop / tablet: permanent side rail
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Row(
        children: [
          SizedBox(width: 260, child: _buildSidebar()),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _darkBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A84F0), Color(0xFF2A5CC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flight_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Overflow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A84F0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        // Avatar
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _navigate(NavSection.settings),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3B6FD4),
              child: Text(
                _currentPilot?.initials ?? '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// NAV TILE
// ---------------------------------------------------------------------------

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isActive
                      ? const Color(0xFF4A84F0)
                      : Colors.white.withOpacity(0.55),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLACEHOLDER SCREEN (Flight History, Analytics)
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B6FD4).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          icon,
                          size: 34,
                          color: const Color(0xFF3B6FD4).withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF6B7280).withOpacity(0.7),
                        ),
                      ),
                    ],
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
