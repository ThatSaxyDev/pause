import 'dart:async';

import 'package:dartnative/dartnative.dart';

import '../features/guard/pause_guard_page.dart';
import '../features/guard/pause_guard_handoff.dart';
import '../features/guard/pause_guard_preferences.dart';
import '../features/home/pause_home.dart';
import '../features/analysis/notifiers/pause_analysis_notifier.dart';
import '../theme/pause_theme.dart';

enum PauseTab { check, guard }

/// App-level navigation state. A signal keeps both destinations mounted, so a
/// partly entered manual check is not discarded when someone reviews Guard.
final pauseSelectedTab = signal<PauseTab>(PauseTab.check);

class PauseShell extends StatefulWidget {
  const PauseShell({super.key});

  @override
  State<PauseShell> createState() => _PauseShellState();
}

class _PauseShellState extends State<PauseShell> with WidgetsBindingObserver {
  Timer? _guardHandoffTimer;
  bool _isConsumingGuardHandoff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _consumeGuardHandoff();
    // onNewIntent does not cause a lifecycle transition when Pause is already
    // foregrounded. Polling this one local, one-shot key closes that Android
    // edge case without retaining notification content.
    _guardHandoffTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _consumeGuardHandoff(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _consumeGuardHandoff();
  }

  Future<void> _consumeGuardHandoff() async {
    if (_isConsumingGuardHandoff) return;
    _isConsumingGuardHandoff = true;
    try {
      final intake = await PauseGuardPreferences.takePendingIntake();
      if (!mounted || intake == null || intake.trim().isEmpty) return;
      pauseSelectedTab.value = PauseTab.check;
      pauseGuardIncomingText.value = intake;
      await pauseAnalysisNotifier.analyse(intake);
    } finally {
      _isConsumingGuardHandoff = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guardHandoffTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedTab = pauseSelectedTab.watch(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // DartNative's IndexedStack can retain a stale visible child while the
      // navigation signal has already changed. Render the selected destination
      // directly so a Guard-warning tap always lands on Check. The analysis
      // state itself lives outside the page and therefore remains intact.
      body: selectedTab == PauseTab.check
          ? const PauseHome()
          : const PauseGuardPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab.index,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconColor: scheme.onSurfaceVariant,
        selectedIconColor: PauseColors.blue,
        labelFontStyle: TextStyle(color: scheme.onSurfaceVariant),
        selectedLabelFontStyle: const TextStyle(color: PauseColors.blue),
        onTap: (index) => pauseSelectedTab.value = PauseTab.values[index],
        items: const [
          BottomNavigationBarItem(
            label: 'Check',
            icon: Icon(MaterialSymbolsRounded.search),
          ),
          BottomNavigationBarItem(
            label: 'Guard',
            icon: Icon(MaterialSymbolsRounded.shield),
          ),
        ],
      ),
    );
  }
}
