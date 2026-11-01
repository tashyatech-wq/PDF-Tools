import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/compress_screen.dart';
import 'screens/merge_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/saved_files_screen.dart';
import 'screens/split_screen.dart';
import 'screens/unlock_screen.dart';
import 'theme.dart';
import 'widgets/ad_mob_banner.dart';
import 'widgets/native_tool_ad.dart';

class _Tool {
  const _Tool({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.homeSubtitle,
    required this.icon,
    required this.color,
    required this.screen,
    this.badge,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String homeSubtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String? badge;
}

enum _ShellTab { home, saved }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _showSplash = true;
  _ShellTab _tab = _ShellTab.home;
  _Tool? _selectedTool;
  Timer? _splashTimer;

  late final List<_Tool> _tools = [
    _Tool(
      id: 'scan',
      title: 'Scan to PDF',
      shortTitle: 'Scan PDF',
      subtitle: 'Camera to PDF',
      homeSubtitle: 'Capture paper as PDF',
      icon: Icons.document_scanner_rounded,
      color: AppColors.scan,
      screen: const ScanScreen(),
      badge: 'New',
    ),
    _Tool(
      id: 'merge',
      title: 'Merge PDF',
      shortTitle: 'Merge PDFs',
      subtitle: 'Combine files into one',
      homeSubtitle: 'Combine documents in order',
      icon: Icons.content_copy_rounded,
      color: AppColors.merge,
      screen: const MergeScreen(),
    ),
    _Tool(
      id: 'split',
      title: 'Split PDF',
      shortTitle: 'Split PDF',
      subtitle: 'Pull pages apart',
      homeSubtitle: 'Extract pages or export all',
      icon: Icons.call_split_rounded,
      color: AppColors.split,
      screen: const SplitScreen(),
    ),
    _Tool(
      id: 'compress',
      title: 'Compress PDF',
      shortTitle: 'Compress PDF',
      subtitle: 'Shrink the file size',
      homeSubtitle: 'Reduce file size for uploads',
      icon: Icons.compress_rounded,
      color: AppColors.compress,
      screen: const CompressScreen(),
    ),
    _Tool(
      id: 'unlock',
      title: 'Unlock PDF',
      shortTitle: 'Unlock PDF',
      subtitle: 'Remove a password',
      homeSubtitle: 'Remove known passwords',
      icon: Icons.lock_open_rounded,
      color: AppColors.unlock,
      screen: const UnlockScreen(),
      badge: 'Mobile',
    ),
  ];

  Color get _accent {
    final tool = _selectedTool;
    if (tool != null) return tool.color;
    return _tab == _ShellTab.saved ? AppColors.split : AppColors.merge;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splashTimer = Timer(const Duration(milliseconds: 1900), () {
        if (mounted) setState(() => _showSplash = false);
      });
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _openTool(_Tool tool) => setState(() {
    _tab = _ShellTab.home;
    _selectedTool = tool;
  });

  void _goHome() => setState(() {
    _tab = _ShellTab.home;
    _selectedTool = null;
  });

  void _goSaved() => setState(() {
    _tab = _ShellTab.saved;
    _selectedTool = null;
  });

  @override
  Widget build(BuildContext context) {
    final isSplash = _showSplash;
    final current = _selectedTool;

    return ToolAccent(
      color: _accent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isSplash
            ? const _SplashScreen()
            : Column(
                children: [
                  _TopBar(
                    tool: current,
                    tab: _tab,
                    accent: _accent,
                    onBack: _goHome,
                  ),
                  Expanded(
                    child: current == null
                        ? _tab == _ShellTab.home
                              ? _HomeScreen(tools: _tools, onToolTap: _openTool)
                              : const SavedFilesScreen()
                        : current.screen,
                  ),
                ],
              ),
        bottomNavigationBar: isSplash
            ? null
            : _BottomArea(currentTab: _tab, onHome: _goHome, onSaved: _goSaved),
      ),
    );
  }
}

class _BottomArea extends StatelessWidget {
  const _BottomArea({
    required this.currentTab,
    required this.onHome,
    required this.onSaved,
  });

  final _ShellTab currentTab;
  final VoidCallback onHome;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              height: 62,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: currentTab == _ShellTab.saved ? 1 : 0,
              onDestinationSelected: (index) {
                if (index == 0) {
                  onHome();
                } else {
                  onSaved();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: 'Saved',
                ),
              ],
            ),
            const AdMobBanner(),
          ],
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF171018), Color(0xFF0B111C), Color(0xFF0F2A24)]
              : const [Color(0xFFFFE7E7), Color(0xFFFFFFFF), Color(0xFFE9FBF7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.merge.withValues(alpha: 0.28),
                        blurRadius: 44,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/icons/app-icon-128.png',
                      width: 118,
                      height: 118,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'PDF Tools',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Safe, secure PDF actions for documents that stay on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 148,
                child: LinearProgressIndicator(
                  minHeight: 5,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: Center(
                  child: SizedBox(
                    width: 310,
                    height: 72,
                    child: Image.asset(
                      'assets/brand/tashya-labs-logo-horizontal.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tool,
    required this.tab,
    required this.accent,
    required this.onBack,
  });

  final _Tool? tool;
  final _ShellTab tab;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isHome = tool == null;
    final title =
        tool?.title ?? (tab == _ShellTab.saved ? 'Saved Files' : 'PDF Tools');
    final subtitle =
        tool?.subtitle ??
        (tab == _ShellTab.saved
            ? 'Your completed PDFs'
            : 'Choose what you need');
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (!isHome) ...[
                  _IconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
                  const SizedBox(width: 10),
                ],
                _BadgeIcon(tool: tool, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _TrustMark(compact: true),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
          ),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.tool, required this.accent});

  final _Tool? tool;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: tool == null
          ? Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset('assets/icons/app-icon-128.png'),
            )
          : Icon(tool!.icon, color: accent, size: 20),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.tools, required this.onToolTap});

  final List<_Tool> tools;
  final ValueChanged<_Tool> onToolTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HomeHero(),
          const SizedBox(height: 18),
          Text(
            'START',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 9),
          GridView.builder(
            itemCount: tools.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              mainAxisExtent: 134,
            ),
            itemBuilder: (context, index) => _ToolCard(
              tool: tools[index],
              onTap: () => onToolTap(tools[index]),
            ),
          ),
          const SizedBox(height: 16),
          const NativeToolAd(),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.merge.withValues(alpha: 0.11),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.merge.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/app-icon-128.png',
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF Tools',
                      style: TextStyle(
                        fontSize: 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Safe PDF tools. Your files stay on your device.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TrustMark(),
        ],
      ),
    );
  }
}

class _TrustMark extends StatelessWidget {
  const _TrustMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.compress;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: compact ? 15 : 16,
          color: color,
        ),
        SizedBox(width: compact ? 4 : 7),
        Text(
          compact
              ? 'Safe & Secure'
              : 'Safe & Secure • Your files never leave your device',
          style: TextStyle(
            fontSize: compact ? 11 : 11.5,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onTap});

  final _Tool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tool.color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              top: -5,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: tool.color.withValues(alpha: 0.72),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 20),
                ),
                const Spacer(),
                Text(
                  tool.shortTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tool.homeSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (tool.badge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tool.badge!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
