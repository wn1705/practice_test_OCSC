import 'package:flutter/material.dart';

class ExamNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ExamNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemTapped,
      indicatorColor: Colors.amber,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.arrow_back), label: 'ก่อนหน้า'),
        NavigationDestination(icon: Icon(Icons.checklist), label: 'ทวนคำตอบ'),
        NavigationDestination(icon: Icon(Icons.arrow_forward), label: 'ถัดไป'),
      ],
    );
  }
}
