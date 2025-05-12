import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habit2/auth.dart';
import 'package:habit2/screens/forget_password.dart';
import 'package:habit2/screens/home.dart';
import 'package:habit2/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit2/screens/signup.dart';
import 'dart:convert';
import 'charts.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Auth(),
      theme: ThemeData(
        fontFamily: 'Lora'
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

class Habit {
  String name;
  int progress;
  int goal;

  Habit({required this.name, this.progress = 0, required this.goal});

  Map<String, dynamic> toJson() => {
    'name': name,
    'progress': progress,
    'goal': goal,
  };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
    name: json['name'],
    progress: json['progress'],
    goal: json['goal'],
  );
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  List<Habit> habits = [];
  List<Habit> completedHabits = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedHabits();
    _setupClearTimer();
  }

  void _loadCompletedHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? completedHabitStrings = prefs.getStringList('completedHabits');

    if (completedHabitStrings != null) {
      completedHabits = completedHabitStrings
          .map((habitString) => Habit.fromJson(json.decode(habitString)))
          .toList();
    }
  }

  void _saveCompletedHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedHabitStrings = completedHabits
        .map((habit) => json.encode(habit.toJson()))
        .toList();
    await prefs.setStringList('completedHabits', completedHabitStrings);
  }

  void _setupClearTimer() {
    Future.delayed(const Duration(hours: 24), () {
      setState(() {
        completedHabits.clear();
        _saveCompletedHabits();
      });
      _setupClearTimer(); // Reset the timer every 24 hours
    });
  }

  void _addHabit() async {
    final Habit? newHabit = await showDialog<Habit>(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
    if (newHabit != null) {
      setState(() {
        habits.add(newHabit);
      });
    }
  }

  void _incrementProgress(int index) {
    setState(() {
      if (habits[index].progress < habits[index].goal) {
        habits[index].progress++;
      }

      if (habits[index].progress == habits[index].goal) {
        final habit = habits[index];
        completedHabits.add(habit);
        _saveCompletedHabits();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit Completed'),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            habits.removeAt(index);
          });
        });
      }
    });
  }

  void _deleteHabit(int index) {
    setState(() {
      habits.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Habit Tracking App'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChartsPage(completedHabits: completedHabits),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/graph_icon.png',
                      width: 70,
                      height: 70,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Check your Progress',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isCompleted = habit.progress >= habit.goal;

                return TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: Colors.white,
                    end: isCompleted ? Color.fromRGBO(223, 123, 39, 1.0) : Colors.white,
                  ),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, color, child) {
                    return Card(
                      color: color,
                      margin: const EdgeInsets.all(12),
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
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: habit.progress / habit.goal,
                                    ),
                                    duration: const Duration(milliseconds: 250),
                                    builder: (context, value, child) {
                                      return CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 6,
                                        color: Colors.red,
                                      );
                                    },
                                  ),
                                ),
                                Text(
                                  '${habit.progress}/${habit.goal}',
                                  style: const TextStyle(fontSize: 12),
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
                              onPressed: isCompleted ? null : () => _incrementProgress(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteHabit(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Habit Name'),
          ),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: 'Times per Week'),
            keyboardType: TextInputType.number,
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
            final name = _nameController.text;
            final goal = int.tryParse(_goalController.text) ?? 1;
            if (name.isNotEmpty) {
              Navigator.of(context).pop(Habit(name: name, goal: goal));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}