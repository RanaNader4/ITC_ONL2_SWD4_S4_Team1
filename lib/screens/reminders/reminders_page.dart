import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../models/reminder.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';

class RemindersPage extends StatefulWidget {
  final List<Habit> habits;

  const RemindersPage({
    Key? key,
    required this.habits,
  }) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<HabitReminder> reminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    if(mounted) setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders');
    if (mounted) {
      setState(() {
        if (remindersJson != null) {
          reminders = remindersJson
              .map((json) => HabitReminder.fromJson(jsonDecode(json)))
              .toList();
        }
        isLoading = false;
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = reminders
        .map((reminder) => jsonEncode(reminder.toJson()))
        .toList();
    await prefs.setStringList('reminders', remindersJson);
  }

  void _addReminder() {
    if (widget.habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to create habits first to add a reminder.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        habits: widget.habits,
        onSave: (reminder) {
          if(mounted) {
            setState(() {
              reminders.add(reminder);
              _saveReminders();
              _scheduleNotification(reminder);
            });
          }
        },
      ),
    );
  }

  void _editReminder(int index) {
    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        habits: widget.habits,
        reminder: reminders[index],
        onSave: (updatedReminder) {
          if(mounted) {
            setState(() {
              reminders[index] = updatedReminder;
              _saveReminders();
              _scheduleNotification(updatedReminder);
            });
          }
        },
      ),
    );
  }

  void _deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final reminder = reminders[index];
              if(mounted) {
                setState(() {
                  reminders.removeAt(index);
                  _saveReminders();
                  _cancelNotification(reminder);
                });
              }
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(int index) {
    if(mounted) {
      setState(() {
        final reminder = reminders[index];
        final updatedReminder = reminder.copyWith(
          isEnabled: !reminder.isEnabled,
        );
        reminders[index] = updatedReminder;
        _saveReminders();
        
        if (updatedReminder.isEnabled) {
          _scheduleNotification(updatedReminder);
        } else {
          _cancelNotification(updatedReminder);
        }
      });
    }
  }

  void _scheduleNotification(HabitReminder reminder) {
    final habitName = _getHabitName(reminder.habitId);
    NotificationService().scheduleReminder(reminder, habitName);
  }

  void _cancelNotification(HabitReminder reminder) {
    NotificationService().cancelReminder(reminder.id);
  }

  String _getHabitName(String habitId) {
    final habit = widget.habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(name: 'Unknown Habit', goal: 1),
    );
    return habit.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No reminders yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addReminder,
                        child: const Text('Add Reminder'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: reminder.isEnabled 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                        title: Text(_getHabitName(reminder.habitId)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time: ${reminder.timeString}'),
                            Text('Days: ${reminder.daysString}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: reminder.isEnabled,
                              onChanged: (_) => _toggleReminder(index),
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editReminder(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteReminder(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReminderDialog extends StatefulWidget {
  final List<Habit> habits;
  final HabitReminder? reminder;
  final Function(HabitReminder) onSave;

  const ReminderDialog({
    Key? key,
    required this.habits,
    this.reminder,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  String? _selectedHabitId;
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<int> _selectedDays = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isEnabled = true;
  final _formKey = GlobalKey<FormState>();

  final List<String> _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _selectedHabitId = widget.reminder!.habitId;
      _selectedTime = widget.reminder!.time;
      _selectedDays = List<int>.from(widget.reminder!.days);
      _messageController.text = widget.reminder!.message;
      _isEnabled = widget.reminder!.isEnabled;
    } else if (widget.habits.isNotEmpty) {
      _selectedHabitId = widget.habits.first.id;
    }
    if (widget.reminder == null && _messageController.text.isEmpty) {
      _updateDefaultMessage();
    }
  }

  void _updateDefaultMessage() {
    if (_selectedHabitId != null) {
      final habitName = widget.habits
          .firstWhere((h) => h.id == _selectedHabitId,
              orElse: () => Habit(name: 'this habit', goal: 1))
          .name;
      _messageController.text = 'Time for your habit: $habitName!';
    } else {
      _messageController.text = 'Time to complete your habit!';
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Habit', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedHabitId,
                items: widget.habits.map((habit) {
                  return DropdownMenuItem<String>(
                    value: habit.id,
                    child: Text(habit.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: widget.habits.isEmpty ? null : (value) {
                  setState(() {
                    _selectedHabitId = value;
                     if (widget.reminder == null) { 
                        _updateDefaultMessage();
                     }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                 validator: (value) => value == null ? 'Please select a habit' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => _pickTime(context),
                    child: Text(
                      _selectedTime.format(context),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Days', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List<Widget>.generate(7, (index) {
                  final dayValue = index + 1; 
                  final isSelected = _selectedDays.contains(dayValue);
                  return ChoiceChip(
                    label: Text(_dayNames[index]),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayValue);
                          _selectedDays.sort();
                        } else {
                          _selectedDays.remove(dayValue);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    checkmarkColor: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                    ),
                  );
                }),
              ),
              ValueListenableBuilder<List<int>>(
                valueListenable: ValueNotifier(_selectedDays),
                builder: (context, days, child) {
                  if (days.isEmpty && _formKey.currentState?.validate() == false) {
                    // Currently, this block does nothing visible. If inline error display is needed,
                    // it would return a Text widget here.
                  }
                  return const SizedBox.shrink(); 
                }
              ),
              const SizedBox(height: 16),
              Text('Reminder Message', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'e.g., Time for your morning run!',
                  border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? 'Message cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enabled', style: Theme.of(context).textTheme.titleMedium),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ),
        ElevatedButton(
          onPressed: () {
            bool daysValid = _selectedDays.isNotEmpty;
            if (!daysValid && mounted) { 
                setState(() {}); 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select at least one day."), backgroundColor: Theme.of(context).colorScheme.error,));
            }

            if (_formKey.currentState!.validate() && daysValid) {
              final reminder = HabitReminder(
                id: widget.reminder?.id ?? const Uuid().v4(),
                habitId: _selectedHabitId!,
                time: _selectedTime,
                days: _selectedDays,
                message: _messageController.text,
                isEnabled: _isEnabled,
              );
              widget.onSave(reminder);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
