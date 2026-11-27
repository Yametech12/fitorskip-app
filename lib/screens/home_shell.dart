/// The signed-in shell: five tabs over the v1 flow.
library;

import 'package:material_ui/material_ui.dart';

import 'about_screen.dart';
import 'credits_screen.dart';
import 'garment_intake_screen.dart';
import 'results_gallery_screen.dart';
import 'wardrobe_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _titles = [
    'FitOrSkip',
    'Results',
    'Wardrobe',
    'Credits',
    'About',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: [
          const GarmentIntakeScreen(),
          ResultsGalleryScreen(onTryOn: () => setState(() => _index = 0)),
          const WardrobeScreen(),
          const CreditsScreen(),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Try on',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.dry_cleaning_outlined),
            selectedIcon: Icon(Icons.dry_cleaning),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Credits',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
