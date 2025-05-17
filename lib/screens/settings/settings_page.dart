import 'package:flutter/material.dart';
import '../achievements/achievements_page.dart';
import '../categories/categories_page.dart';
import '../reminders/reminders_page.dart';
import '../../models/habit.dart';

class SettingsPage extends StatelessWidget {
  final List<Habit> habits;

  const SettingsPage({
    Key? key,
    required this.habits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        children: [
          _buildSettingItem(
            context,
            'Achievements',
            Icons.emoji_events,
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AchievementsPage()),
            ),
          ),
          _buildSettingItem(
            context,
            'Categories',
            Icons.category,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesPage()),
            ),
          ),
          _buildSettingItem(
            context,
            'Reminders',
            Icons.notifications,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RemindersPage(habits: habits),
              ),
            ),
          ),
          const Divider(),
          _buildSettingItem(
            context,
            'About',
            Icons.info,
            Colors.grey,
            () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Habit Tracker'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habit Tracker App'),
            SizedBox(height: 8),
            Text('Version 1.1.0'),
            SizedBox(height: 16),
            Text(
              'A simple app to help you build and maintain good habits.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
