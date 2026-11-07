import 'package:flutter/material.dart';

import '../../app/widgets/widgets.dart';
import '../../copy/text.dart';
import '../cellar_book/cellar_book_screen.dart';
import '../instructions/instructions_screen.dart';
import '../today/today_screen.dart';

/// Today · Cellar Book · Instructions.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: const [
            TodayScreen(),
            CellarBookScreen(),
            InstructionsScreen(),
          ],
        ),
        bottomNavigationBar: LedgerTabs(
          labels: const [
            CommonText.today,
            CommonText.cellarBook,
            CommonText.instructions,
          ],
          index: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}
