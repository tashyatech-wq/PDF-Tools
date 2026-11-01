import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/force_update_service.dart';
import '../theme.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  late Future<ForceUpdateDecision> _decision;

  @override
  void initState() {
    super.initState();
    _decision = ForceUpdateService.check();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ForceUpdateDecision>(
      future: _decision,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CheckingUpdateScreen();
        }

        final decision = snapshot.data;
        if (decision != null && decision.requiresUpdate) {
          return ForceUpdateScreen(decision: decision);
        }

        return widget.child;
      },
    );
  }
}

class _CheckingUpdateScreen extends StatelessWidget {
  const _CheckingUpdateScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/icons/app-icon-128.png',
                width: 74,
                height: 74,
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 128,
              child: LinearProgressIndicator(
                minHeight: 5,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.decision});

  final ForceUpdateDecision decision;

  Future<void> _openStore(BuildContext context) async {
    final url = decision.storeUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store link is not configured yet.')),
      );
      return;
    }

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the store link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.merge;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.24),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/icons/app-icon-128.png',
                    width: 112,
                    height: 112,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Update Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                decision.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Installed ${decision.currentVersion} • Required ${decision.minimumVersion}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openStore(context),
                  icon: const Icon(Icons.system_update_alt_rounded),
                  label: const Text('Update Now'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You need the latest version to continue using PDF Tools.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
