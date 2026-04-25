import 'package:certipath_app/features/scan/presentation/scan_page.dart';
import 'package:flutter/material.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../../../core/theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  final List<Widget> _pages = const [HomePage(), ScanQrPage(), ProfilePage()];

  void _onTap(int index) {
    setState(() => _index = index);
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? Colors.black : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? Colors.black : Colors.grey,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],

      floatingActionButton: GestureDetector(
        onTap: () => _onTap(1),
        child: Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home,
                label: 'Home',
                active: _index == 0,
                onTap: () => _onTap(0),
              ),

              const SizedBox(width: 40),

              _navItem(
                icon: Icons.person,
                label: 'Profile',
                active: _index == 2,
                onTap: () => _onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
