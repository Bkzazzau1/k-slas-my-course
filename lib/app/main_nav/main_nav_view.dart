import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/courses/view/courses_list_view.dart';
import '../../features/dashboard/view/dashboard_view.dart';
import '../../modules/settings/view/settings_view.dart';

class MainNavView extends StatelessWidget {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavController(), permanent: true);

    return Obx(() {
      final width = MediaQuery.sizeOf(context).width;
      final useRail = width >= 900;
      final destinations = _NavDestination.items;

      return Scaffold(
        body: Row(
          children: [
            if (useRail)
              NavigationRail(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                extended: width >= 1180,
                minExtendedWidth: 190,
                labelType: width >= 1180
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                  child: _BrandMark(extended: width >= 1180),
                ),
                destinations: destinations
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: IndexedStack(
                index: controller.index.value,
                children: const [
                  DashboardView(),
                  CoursesListView(),
                  SettingsView(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                destinations: destinations
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
      );
    });
  }
}

class MainNavController extends GetxController {
  final index = 0.obs;

  void setIndex(int i) => index.value = i;
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  static const items = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavDestination(
      label: 'Courses',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.school_outlined, color: Colors.white),
        ),
        if (extended) ...[
          const SizedBox(width: 10),
          Text(
            'K-SLAS',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}
