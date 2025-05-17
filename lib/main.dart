import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit2/auth.dart';
import 'package:habit2/screens/forget_password.dart';
import 'package:habit2/screens/home.dart';
import 'package:habit2/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit2/screens/signup.dart';
import 'dart:convert';
import 'charts.dart';
import 'models/habit.dart';
import 'models/category.dart';
import 'models/achievement.dart';
import 'models/reminder.dart';
import 'services/notification_service.dart';
import 'services/achievement_service.dart';
import 'services/category_service.dart';
import 'screens/settings/settings_page.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:habit2/screens/reminders/reminders_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.scheduleEngagementNotification();
    
    var notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      print("Notification permission is denied. Requesting...");
      await Permission.notification.request();
    }
    notificationStatus = await Permission.notification.status;
    print("Notification permission status: $notificationStatus");

    if (await Permission.scheduleExactAlarm.isDenied) {
       print("SCHEDULE_EXACT_ALARM permission is denied. User may need to grant it in settings.");
    } else if (await Permission.scheduleExactAlarm.isGranted) {
      print("SCHEDULE_EXACT_ALARM permission is granted.");
    } else {
      print("SCHEDULE_EXACT_ALARM permission status: ${await Permission.scheduleExactAlarm.status}");
    }
    
    final achievementService = AchievementService();
    await achievementService.init();
    
    final categoryService = CategoryService();
    await categoryService.init();
  } catch (e) {
    print('Error initializing services: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Auth(),
      theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      routes: {
        'toLoginScreen' : (context) => LoginScreen(),
        'toSignupScreen' : (context) => SignupScreen(),
        'toForgetPassword' : (context) => ForgetPassword(),
        'toHomeScreen' : (context) => HomeScreen(),
        'toAuth' : (context) => Auth()
      },
    );
  }
}

class HabitTrackingApp extends StatelessWidget {
  const HabitTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HabitHomePage(),
    );
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Habit> habits = [];
  List<Habit> completedHabits = [];
  List<Achievement> _achievements = [];
  bool _isLoadingAchievements = true;
  List<HabitReminder> _globalReminders = [];
  bool _isLoadingGlobalReminders = true;
  List<HabitCategory> _categories = [];
  bool _isLoadingCategories = true;

  final AchievementService _achievementService = AchievementService();
  final CategoryService _categoryService = CategoryService();
  TabController? _tabController;
  int _currentTabIndex = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        // Do nothing if the index is already changing
      } else {
        setState(() {
          _currentTabIndex = _tabController!.index;
          print("Current Tab Index: $_currentTabIndex");
        });
      }
    });
    _loadHabits();
    _loadCompletedHabits();
    _setupClearTimer();
    _fetchAchievements();
    _loadGlobalReminders();
    _fetchCategories();
  }

  @override
  void dispose() {
    _tabController?.removeListener(() {});
    _tabController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      print("App is paused or detached. Scheduling motivational notification.");
      _notificationService.scheduleMotivationNotification();
    }
  }

  void _loadHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? habitStrings = prefs.getStringList('habits');

    if (habitStrings != null) {
      setState(() {
        habits = habitStrings.map((habitString) {
          final Map<String, dynamic> jsonData = json.decode(habitString);
          if (!jsonData.containsKey('id')) {
            return Habit(
              name: jsonData['name'],
              progress: jsonData['progress'],
              goal: jsonData['goal'],
              categoryId: 'other',
            );
          } else {
            return Habit.fromJson(jsonData);
          }
        }).toList();
      });
    }
  }

  void _loadCompletedHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? completedHabitStrings = prefs.getStringList('completedHabits');

    if (completedHabitStrings != null) {
      completedHabits = completedHabitStrings.map((habitString) {
        final Map<String, dynamic> jsonData = json.decode(habitString);
        if (!jsonData.containsKey('id')) {
          return Habit(
            name: jsonData['name'],
            progress: jsonData['progress'],
            goal: jsonData['goal'],
            categoryId: 'other',
          );
        } else {
          return Habit.fromJson(jsonData);
        }
      }).toList();
    }
    _checkAndResetCompletedHabits();
  }

  void _saveHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> habitStrings = habits
        .map((habit) => json.encode(habit.toJson()))
        .toList();
    await prefs.setStringList('habits', habitStrings);
  }

  void _saveCompletedHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedHabitStrings = completedHabits
        .map((habit) => json.encode(habit.toJson()))
        .toList();
    await prefs.setStringList('completedHabits', completedHabitStrings);
  }

  void _setupClearTimer() {
    Future.delayed(const Duration(minutes: 30), () {
      _checkAndResetCompletedHabits();
      _setupClearTimer();
    });
  }
  
  void _checkAndResetCompletedHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastResetTime = prefs.getInt('lastHabitResetTime');
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (lastResetTime == null || currentTime - lastResetTime >= 24 * 60 * 60 * 1000) {
      setState(() {
        completedHabits.clear();
        _saveCompletedHabits();
      });
      await prefs.setInt('lastHabitResetTime', currentTime);
    }
  }

  Future<void> _fetchAchievements() async {
    try {
      final achievements = await _achievementService.getAchievements();
      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoadingAchievements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAchievements = false;
        });
        print("Error fetching achievements: $e");
      }
    }
  }

  Future<void> _loadGlobalReminders() async {
    setState(() {
      _isLoadingGlobalReminders = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('reminders');
      if (mounted) {
        if (remindersJson != null) {
          setState(() {
            _globalReminders = remindersJson
                .map((json) => HabitReminder.fromJson(jsonDecode(json)))
                .toList();
          });
        }
        setState(() {
          _isLoadingGlobalReminders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGlobalReminders = false;
        });
        print("Error fetching global reminders: $e");
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() { _isLoadingCategories = true; });
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingCategories = false; });
        print("Error fetching categories in HomePage: $e");
      }
    }
  }

  void _addHabit() async {
    final Habit? newHabit = await showDialog<Habit>(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );

    if (newHabit != null) {
      setState(() {
        habits.add(newHabit);
        _saveHabits();
        _checkAchievementsOnHabitChange();
      });
    }
  }

  void _incrementProgress(int index) {
    bool wasCompleted = habits[index].isCompleted;
    final String habitIdBeingWorkedOn = habits[index].id;

    setState(() {
      if (habits[index].progress < habits[index].goal) {
        habits[index].progress++;
        _saveHabits();
      }

      if (index < habits.length && 
          habits[index].id == habitIdBeingWorkedOn && 
          habits[index].progress >= habits[index].goal && 
          !wasCompleted) {
        
        final completedHabitInstance = habits[index];
        
        Habit completedVersion = completedHabitInstance.copyWith(progress: completedHabitInstance.goal);
        completedHabits.add(completedVersion);
        _saveCompletedHabits();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit Completed'),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
          setState(() {
              int currentIndex = habits.indexWhere((h) => h.id == habitIdBeingWorkedOn);
              if (currentIndex != -1) {
                habits.removeAt(currentIndex);
            _saveHabits();

                List<HabitReminder> updatedGlobalReminders = [];
                List<HabitReminder> removedGlobalReminders = [];

                for (final reminder in _globalReminders) {
                  if (reminder.habitId == habitIdBeingWorkedOn) {
                    NotificationService().cancelReminder(reminder.id);
                    removedGlobalReminders.add(reminder);
                    print("[HabitHomePage] Identified reminder ${reminder.id} for deletion (completed habit: ${habitIdBeingWorkedOn})");
                  } else {
                    updatedGlobalReminders.add(reminder);
                  }
                }

                if (removedGlobalReminders.isNotEmpty) {
                  _globalReminders = updatedGlobalReminders;
                  _saveGlobalReminders();
                  print("[HabitHomePage] ${removedGlobalReminders.length} reminders removed for completed habit ${habitIdBeingWorkedOn}");
                }
              }
              _checkAchievementsOnHabitChange();
            });
          }
        });
      } else if (index < habits.length && habits[index].id == habitIdBeingWorkedOn && habits[index].progress < habits[index].goal) {
        _checkAchievementsOnHabitChange();
      }
    });
  }

  void _deleteHabit(int index) {
    final habitToDelete = habits[index];
    final String habitIdToDelete = habitToDelete.id;

    setState(() {
      List<HabitReminder> updatedGlobalReminders = [];
      List<HabitReminder> removedGlobalReminders = [];

      for (final reminder in _globalReminders) {
        if (reminder.habitId == habitIdToDelete) {
          NotificationService().cancelReminder(reminder.id);
          removedGlobalReminders.add(reminder);
          print("[HabitHomePage] Identified reminder ${reminder.id} for deletion (habit: ${habitIdToDelete})");
        } else {
          updatedGlobalReminders.add(reminder);
        }
      }

      if (removedGlobalReminders.isNotEmpty) {
        _globalReminders = updatedGlobalReminders;
        _saveGlobalReminders();
        print("[HabitHomePage] ${removedGlobalReminders.length} reminders removed for habit ${habitIdToDelete}");
      }

      habits.removeAt(index);
      _saveHabits();
      _checkAchievementsOnHabitChange();
      print("[HabitHomePage] Deleted habit ${habitIdToDelete} and handled associated reminders.");
    });
  }

  Future<void> _checkAchievementsOnHabitChange() async {
    final unlockedAchievement = await _achievementService.checkAndUnlockAchievements(habits, completedHabits);
    if (unlockedAchievement != null && mounted) {
      await _fetchAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Achievement Unlocked: ${unlockedAchievement.title}!'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getHabitNameForReminder(String habitId) {
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(name: 'Unknown Habit', goal: 1),
    );
    return habit.name;
  }

  Future<void> _saveGlobalReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _globalReminders
          .map((reminder) => jsonEncode(reminder.toJson()))
          .toList();
      await prefs.setStringList('reminders', remindersJson);
    } catch (e) {
      print("Error saving global reminders: $e");
    }
  }

  void _editReminderFromMain(String reminderIdToEdit) async {
    final reminderIndex = _globalReminders.indexWhere((r) => r.id == reminderIdToEdit);
    if (reminderIndex == -1) return;

    final HabitReminder? updatedReminder = await showDialog<HabitReminder>(
      context: context,
      builder: (context) => ReminderDialog(
        habits: habits,
        reminder: _globalReminders[reminderIndex],
        onSave: (editedReminder) {
          Navigator.of(context).pop(editedReminder);
        },
      ),
    );

    if (updatedReminder != null && mounted) {
      setState(() {
        _globalReminders[reminderIndex] = updatedReminder;
        _saveGlobalReminders();
        final habitName = _getHabitNameForReminder(updatedReminder.habitId);
        if (updatedReminder.isEnabled) {
          NotificationService().scheduleReminder(updatedReminder, habitName);
        } else {
          NotificationService().cancelReminder(updatedReminder.id);
        }
      });
    }
  }

  void _addReminderFromHomePage() async {
    if (habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to create habits first to assign a reminder.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final HabitReminder? newReminder = await showDialog<HabitReminder>(
      context: context,
      builder: (context) => ReminderDialog(
        habits: habits,
        onSave: (createdReminder) {
          Navigator.of(context).pop(createdReminder);
        },
      ),
    );

    if (newReminder != null && mounted) {
      setState(() {
        _globalReminders.add(newReminder);
        _saveGlobalReminders();
        final habitName = _getHabitNameForReminder(newReminder.habitId);
        if (newReminder.isEnabled) {
          NotificationService().scheduleReminder(newReminder, habitName);
        } else {
          NotificationService().cancelReminder(newReminder.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder for "${_getHabitNameForReminder(newReminder.habitId)}" added.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activeRemindersDisplayList = [];
    if (!_isLoadingGlobalReminders) {
      for (var reminder in _globalReminders) {
        if (reminder.isEnabled) {
          activeRemindersDisplayList.add({
            'habitName': _getHabitNameForReminder(reminder.habitId),
            'reminderTime': reminder.timeString,
            'reminderDays': reminder.daysString,
            'habitId': reminder.habitId,
            'reminderId': reminder.id
          });
        }
      }
      activeRemindersDisplayList.sort((a, b) => a['reminderTime'].compareTo(b['reminderTime']));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        title: Text(
          'Habit Tracker', 
          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChartsPage(completedHabits: completedHabits),
                  settings: RouteSettings(arguments: habits),
                ),
              );
            },
            tooltip: 'View Charts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All Habits'),
            Tab(text: 'Reminders'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Test Immediate Notification'),
              onTap: () {
                Navigator.pop(context);
                NotificationService().flutterLocalNotificationsPlugin.show(
                  888,
                  'Test Notification',
                  'This is an immediate test notification!',
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'test_channel', 
                      'Test Channel',
                      channelDescription: 'Channel for testing immediate notifications',
                      importance: Importance.max,
                      priority: Priority.high,
                    ),
                    iOS: DarwinNotificationDetails(presentSound: true, presentBadge: true, presentAlert: true),
                  ),
                );
                print('Attempted to show immediate test notification.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Test Motivational Notification'),
              onTap: () {
                Navigator.pop(context);
                _notificationService.scheduleMotivationNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scheduled a motivational notification (30s delay).'),
                    duration: Duration(seconds: 3),
                  ),
                );
                print('Attempted to schedule a motivational notification (30s delay).');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); 
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('toAuth');
            },
          ),
        ],
      ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodaysAgendaTab(),
          _buildAllHabitsTab(),
          _buildRemindersTab(activeRemindersDisplayList),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentTabIndex == 2) {
            _addReminderFromHomePage();
          } else {
            _addHabit();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(
          _currentTabIndex == 2 ? Icons.notification_add : Icons.add,
          color: Colors.white70,
        ),
        tooltip: _currentTabIndex == 2 ? 'Add Reminder' : 'Add Habit',
      ),
    );
  }

  Widget _buildTodaysAgendaTab() {
    if (_isLoadingGlobalReminders || _isLoadingCategories) { 
      return const Center(child: CircularProgressIndicator());
    }

    final List<Habit> todaysHabits = habits.where((h) => !h.isCompleted).toList();

    if (todaysHabits.isEmpty && habits.every((h) => h.isCompleted)) {
      return const Center(child: Text("All habits completed for today! 🎉"));
    }
    if (todaysHabits.isEmpty) {
        return const Center(child: Text("No active habits for today. Add some or check 'All Habits'."));
    }

    final categoryMap = { for (var cat in _categories) cat.id : cat };

    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: todaysHabits.length,
        itemBuilder: (context, index) {
            final habit = todaysHabits[index];
            final HabitCategory category = categoryMap[habit.categoryId] ?? 
                                       categoryMap['other'] ?? 
                                       HabitCategory(id: 'other', name: 'Other', icon: Icons.help_outline, color: Colors.grey);
            
            final originalIndex = habits.indexWhere((h) => h.id == habit.id);

            return _HabitAgendaItem(
              habit: habit, 
              category: category,
              onTap: () {
                if (originalIndex != -1) {
                  _incrementProgress(originalIndex);
                }
              },
            );
        },
    );
  }

  Widget _buildAllHabitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChartsPage(completedHabits: completedHabits),
                    settings: RouteSettings(arguments: habits),
                  ),
                );
              },
              child: Card(
                elevation: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/graph_icon.png',
                        width: 60,
                        height: 60,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Check your Progress',
                      style: TextStyle(
                          fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAchievements)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ))
          else if (_achievements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HexColor('#6c1448')),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
            child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = _achievements[index];
                        return Card(
                          elevation: 2,
                          color: achievement.isUnlocked ? Colors.amber[100] : Colors.grey[200],
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                achievement.isUnlocked 
                                  ? Icon(Icons.emoji_events, color: Colors.amber, size: 30)
                                  : Icon(Icons.lock_outline, color: Colors.grey[600], size: 30),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: achievement.isUnlocked ? Colors.black87 : Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), 
            child: Text(
              'Your Habits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HexColor('#4a4a4a')),
            ),
          ),
          const SizedBox(height: 8),
          if (habits.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No habits added yet. Tap '+' to start!"),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return _buildHabitCard(habits[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab(List<Map<String, dynamic>> activeRemindersDisplayList) {
    if (_isLoadingGlobalReminders)
      return const Center(child: CircularProgressIndicator());
    if (activeRemindersDisplayList.isEmpty)
      return const Center(child: Text("No active reminders set.", style: TextStyle(fontStyle: FontStyle.italic)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: activeRemindersDisplayList.length,
      itemBuilder: (context, index) {
        final reminderItem = activeRemindersDisplayList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            leading: Icon(Icons.notifications_active, color: HexColor('#916d35')),
            title: Text(reminderItem['habitName']!),
            subtitle: Text('${reminderItem['reminderTime']} - ${reminderItem['reminderDays']}'),
            onTap: () {
              _editReminderFromMain(reminderItem['reminderId']!); 
            },
          ),
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit, int index) {
      final isCompleted = habit.progress >= habit.goal;
                    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 60,
                                  width: 60,
                    child: CircularProgressIndicator(
                      value: habit.progress / habit.goal,
                                        strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                  ),
                                ),
                                Text(
                                  '${habit.progress}/${habit.goal}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                habit.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                color: Colors.green,
                              onPressed: isCompleted ? null : () => _incrementProgress(index),
                tooltip: 'Increment Progress',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                color: Colors.redAccent,
                              onPressed: () => _deleteHabit(index),
                tooltip: 'Delete Habit',
                            ),
                          ],
                        ),
                      ),
                    );
  }
}

class _HabitAgendaItem extends StatelessWidget {
  final Habit habit;
  final HabitCategory category;
  final VoidCallback onTap;

  const _HabitAgendaItem({
    Key? key,
    required this.habit,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progressPercentage = habit.goal > 0 ? habit.progress / habit.goal : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 90,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        bottomLeft: Radius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(category.icon, size: 20, color: Colors.grey[600]),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
              },
                                child: Row(
                                  key: ValueKey<bool>(habit.isCompleted),
                                  children: [
                                    Icon(Icons.circle, size: 8, color: habit.isCompleted ? Colors.green : Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      habit.isCompleted ? 'Completed!' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: habit.isCompleted ? FontWeight.bold : FontWeight.normal,
                                        color: habit.isCompleted ? Colors.green : Colors.grey[700],
            ),
          ),
        ],
      ),
                              ),
                              const SizedBox(width: 8),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, right: 12.0, bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: category.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          '${habit.progress}/${habit.goal}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  String? _nameError;
  String? _goalError;
  String? _categoryError;

  List<HabitCategory> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          if (_categories.isNotEmpty) {
            final otherCategory = _categories.firstWhere((c) => c.id == 'other', orElse: () => _categories.first);
            _selectedCategoryId = otherCategory.id;
          }
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        print("Error fetching categories: $e");
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Habit Name',
              errorText: _nameError,
            ),
          ),
          TextField(
            controller: _goalController,
            decoration: InputDecoration(
              labelText: 'Times per Week',
              errorText: _goalError,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _isLoadingCategories
              ? const CircularProgressIndicator()
              : _categories.isEmpty
                  ? const Text("Could not load categories. Please try again or add categories in settings.")
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        errorText: _categoryError,
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      isExpanded: true,
                      items: _categories.map((HabitCategory category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategoryId = newValue;
                          _categoryError = null;
                        });
                      },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            bool isValid = true;
            setState(() {
              _nameError = null;
              _goalError = null;
              _categoryError = null;
              
              if (_nameController.text.isEmpty) {
                _nameError = 'Habit name cannot be empty';
                isValid = false;
              }
              
              int? goal = int.tryParse(_goalController.text);
              if (_goalController.text.isEmpty) {
                _goalError = 'Please enter a number';
                isValid = false;
              } else if (goal == null) {
                _goalError = 'Please enter a valid number';
                isValid = false;
              } else if (goal <= 0) {
                _goalError = 'Goal must be greater than 0';
                isValid = false;
              }

              if (_selectedCategoryId == null && _categories.isNotEmpty) {
                _categoryError = 'Please select a category';
                isValid = false;
              }
            });
            
            if (isValid) {
              final name = _nameController.text;
              final goal = int.tryParse(_goalController.text) ?? 1;
              final categoryId = _selectedCategoryId ?? _categories.firstWhere((c) => c.id == 'other', orElse: () => HabitCategory(id: 'other', name: 'Other', icon: Icons.error, color: Colors.grey)).id;

              Navigator.of(context).pop(Habit(
                name: name, 
                goal: goal,
                categoryId: categoryId,
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}