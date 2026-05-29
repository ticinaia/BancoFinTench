import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  static const _routes = <String>[
    AppRoutes.home,
    AppRoutes.pixTransfer,
    AppRoutes.pixHistory,
    AppRoutes.security,
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final routeName = _routes[index];
    if (routeName == AppRoutes.home) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      ModalRoute.withName(AppRoutes.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pix_outlined),
          activeIcon: Icon(Icons.pix_rounded),
          label: 'Pix',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shield_outlined),
          activeIcon: Icon(Icons.shield_rounded),
          label: 'Segurança',
        ),
      ],
    );
  }
}
