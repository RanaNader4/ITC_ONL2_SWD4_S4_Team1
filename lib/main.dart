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

// Global ValueNotifier for ThemeMode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('themeMode');
  if (themeModeString == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }
  
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
    // Define a light theme
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        titleTextStyle: GoogleFonts.lato(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: 20),
      ),
      textTheme: GoogleFonts.latoTextTheme(ThemeData.light().textTheme),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        backgroundColor: Colors.grey[100]!,
      ).copyWith(
          secondary: Colors.amber,
          surfaceVariant: Colors.grey[300],
          outline: Colors.grey[400]),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white70,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.deepPurple,
      ),
      dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          titleTextStyle: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          contentTextStyle: GoogleFonts.lato(fontSize: 16, color: Colors.black87))
    );

    // Define a dark theme
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20),
      ),
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark()
          .textTheme
          .apply(bodyColor: Colors.white70, displayColor: Colors.white)),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF121212),
      ).copyWith(
          secondary: Colors.amberAccent,
          surfaceVariant: const Color(0xFF303030),
          outline: Colors.grey[700]),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.deepPurpleAccent[100],
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: Colors.deepPurpleAccent[100],
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        titleTextStyle: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: GoogleFonts.lato(fontSize: 16, color: Colors.white70)
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          home: Auth(),
          routes: {
            'toLoginScreen' : (context) => LoginScreen(),
            'toSignupScreen' : (context) => SignupScreen(),
            'toForgetPassword' : (context) => ForgetPassword(),
            'toHomeScreen' : (context) => HomeScreen(),
            'toAuth' : (context) => Auth()
          },
        );
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

  Future<void> _setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.dark) {
      modeString = 'dark';
    } else {
      modeString = 'system';
    }
    await prefs.setString('themeMode', modeString);
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

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Tracker',
            ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: isDarkMode ? Colors.white70 : Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ChartsPage(completedHabits: completedHabits),
                  settings: RouteSettings(arguments: habits),
                ),
              );
            },
            tooltip: 'View Charts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
              child: Text(
                'Menu',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              trailing: DropdownButton<ThemeMode>(
                value: themeNotifier.value,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: (ThemeMode? newMode) {
                  if (newMode != null) {
                    _setThemeMode(newMode);
                  }
                },
                dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text('Test Immediate Notification', style: Theme.of(context).textTheme.titleMedium),
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
                          channelDescription:
                              'Channel for testing immediate notifications',
                          importance: Importance.max,
                          priority: Priority.high,
                        ),
                        iOS: DarwinNotificationDetails(
                            presentSound: true,
                            presentBadge: true,
                            presentAlert: true),
                      ),
                    );
                print('Attempted to show immediate test notification.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: Text('Test Motivational Notification (Multiple)', style: Theme.of(context).textTheme.titleMedium),
              onTap: () {
                Navigator.pop(context);
                _notificationService.scheduleMotivationNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Scheduled motivational notifications (various delays).'),
                    duration: Duration(seconds: 3),
                  ),
                );
                print(
                    'Attempted to schedule motivational notifications (various delays).');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout', style: Theme.of(context).textTheme.titleMedium),
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
        child: Icon(
          _currentTabIndex == 2 ? Icons.notification_add : Icons.add,
        ),
        tooltip: _currentTabIndex == 2 ? 'Add Reminder' : 'Add Habit',
      ),
    );
  }

  Widget _buildTodaysAgendaTab() {
    if (_isLoadingGlobalReminders || _isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Habit> todaysHabits =
        habits.where((h) => !h.isCompleted).toList();

    if (todaysHabits.isEmpty && habits.every((h) => h.isCompleted)) {
      return Center(
          child: Text("All habits completed for today! 🎉",
              style: Theme.of(context).textTheme.titleMedium));
    }
    if (todaysHabits.isEmpty) {
      return Center(
          child: Text("No active habits for today. Add some or check 'All Habits'.",
              style: Theme.of(context).textTheme.titleMedium));
    }

    final categoryMap = {for (var cat in _categories) cat.id: cat};

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: todaysHabits.length,
      itemBuilder: (context, index) {
        final habit = todaysHabits[index];
        final HabitCategory category = categoryMap[habit.categoryId] ??
            categoryMap['other'] ??
            HabitCategory(
                id: 'other',
                name: 'Other',
                icon: Icons.help_outline,
                color: Colors.grey);

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color achievementsTitleColor = isDarkMode ? Colors.purple.shade200 : HexColor('#6c1448');
    final Color yourHabitsTitleColor = isDarkMode ? Colors.grey.shade300 : HexColor('#4a4a4a');
    final Color achievementLockedIconColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;
    final Color achievementLockedTextColor = isDarkMode ? Colors.white70 : Colors.grey[700]!;
    final Color? unlockedAchievementCardColor = isDarkMode ? Colors.amber[700]?.withOpacity(0.3) : Colors.amber[100];
    final Color? lockedAchievementCardColor = isDarkMode ? Theme.of(context).cardTheme.color : Colors.grey[200];

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
                    builder: (context) =>
                        ChartsPage(completedHabits: completedHabits),
                    settings: RouteSettings(arguments: habits),
                  ),
                );
              },
              child: Card(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/graph_icon.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        'Check your Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAchievements)
            const Center(
                child: Padding(
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
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: achievementsTitleColor),
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
                          color: achievement.isUnlocked ? unlockedAchievementCardColor : lockedAchievementCardColor,
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                achievement.isUnlocked
                                    ? Icon(Icons.emoji_events,
                                        color: Colors.amber, size: 30)
                                    : Icon(Icons.lock_outline,
                                        color: achievementLockedIconColor, size: 30),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: achievement.isUnlocked
                                        ? (isDarkMode ? Colors.white : Colors.black87)
                                        : achievementLockedTextColor,
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
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: yourHabitsTitleColor),
            ),
          ),
          const SizedBox(height: 8),
          if (habits.isEmpty)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("No habits added yet. Tap '+' to start!", style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildRemindersTab(
      List<Map<String, dynamic>> activeRemindersDisplayList) {
    if (_isLoadingGlobalReminders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activeRemindersDisplayList.isEmpty) {
      return Center(
          child: Text("No active reminders set.",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: activeRemindersDisplayList.length,
      itemBuilder: (context, index) {
        final reminderItem = activeRemindersDisplayList[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.notifications_active,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.amberAccent.shade100 : HexColor('#916d35')),
            title: Text(reminderItem['habitName']!),
            subtitle: Text(
                '${reminderItem['reminderTime']} - ${reminderItem['reminderDays']}'),
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
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
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary.withOpacity(0.8)),
                  ),
                ),
                Text(
                  '${habit.progress}/${habit.goal}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                habit.name,
                style: Theme.of(context).textTheme.titleMedium,
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
    final double progressPercentage =
        habit.goal > 0 ? habit.progress / habit.goal : 0.0;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pendingStatusColor = isDarkMode ? Colors.orangeAccent.shade100 : Colors.orangeAccent;
    final Color completedStatusColor = isDarkMode ? Colors.greenAccent.shade100 : Colors.green;
    final Color statusTextColor = habit.isCompleted ? completedStatusColor : (isDarkMode ? Colors.orangeAccent.shade100 : Colors.orange.shade700);
    final Color categoryIconColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  children: [
                    Text(habit.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                        },
                        child: Row(key: ValueKey<bool>(habit.isCompleted), children: [
                          Icon(Icons.circle, size: 8, color: habit.isCompleted ? completedStatusColor : pendingStatusColor),
                          const SizedBox(width: 4),
                          Text(
                            habit.isCompleted ? 'Completed!' : 'Pending',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: statusTextColor, fontWeight: habit.isCompleted ? FontWeight.bold : FontWeight.normal),
                          ),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 12.0, bottom: 12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(isDarkMode ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(category.icon, size: 14, color: category.color),
                    const SizedBox(width: 4),
                    Text(
                      category.name,
                      style: TextStyle(color: category.color, fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(height: 25),
                Text('${habit.progress}/${habit.goal}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(category.color),
              ),
            ),
          ),
        ]),
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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if(mounted) setState(() => _isLoadingCategories = true);
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
      if (mounted) setState(() => _isLoadingCategories = false);
      print("Error fetching categories for dialog: $e");
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
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Habit Name',
                errorText: _nameError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Habit name cannot be empty';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalController,
              decoration: InputDecoration(
                labelText: 'Times per Week',
                errorText: _goalError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a number';
                final n = int.tryParse(value);
                if (n == null) return 'Please enter a valid number';
                if (n <= 0) return 'Goal must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Text("Could not load categories.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error))
                    : DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          errorText: _categoryError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        validator: (value) => value == null ? 'Please select a category' : null,
                    ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            setState(() {
              _nameError = null;
              _goalError = null;
              _categoryError = null;
            });

            if (_formKey.currentState!.validate()) {
              final name = _nameController.text;
              final goal = int.parse(_goalController.text);
              final categoryId = _selectedCategoryId!;

              Navigator.of(context).pop(Habit(
                name: name, goal: goal, categoryId: categoryId,
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}