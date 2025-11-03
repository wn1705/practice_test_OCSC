import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sub_details.dart';
import '../screens/dashboard.dart';
import '../screens/exam_history.dart';
import '../screens/profile.dart';

// void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationExample();
  }
}

// คลาสหลักที่ใช้ Navigation Bar
class NavigationExample extends StatefulWidget {
  final int initialIndex;

  const NavigationExample({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _NavigationExampleState createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  late int currentPageIndex;
  String? userId;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.initialIndex;
    fetchUserId();
  }

  void fetchUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  void onTabTapped(int index) {
    setState(() {
      currentPageIndex = index;
    });
    // ใช้ Navigator.pushReplacementNamed เพื่อให้ไม่ซ้อนกัน
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 0)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 1)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 2)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Dashboard(exam_id: '',),
      userId != null
          ? ExamHistory(userId: userId!)
          : const Center(child: CircularProgressIndicator()),
      const Profile(),
    ];

    return Scaffold(
      body: pages[currentPageIndex],
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: currentPageIndex,
        onTap: onTabTapped,
      ),
    );
  }
}

// แยก Bottom Navigation Bar ออกมาเป็น Widget
class MyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: onTap,
      indicatorColor: Colors.amber,
      selectedIndex: currentIndex,
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'หน้าหลัก',
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          label: 'ประวัติการทำข้อสอบ',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu),
          label: 'บัญชี',
        ),
      ],
    );
  }
}
