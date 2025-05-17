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
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders');

    if (remindersJson != null) {
      reminders = remindersJson
          .map((json) => HabitReminder.fromJson(jsonDecode(json)))
          .toList();
    }

    setState(() {
      isLoading = false;
    });
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
        const SnackBar(
          content: Text('You need to create habits first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        habits: widget.habits,
        onSave: (reminder) {
          setState(() {
            reminders.add(reminder);
            _saveReminders();
            _scheduleNotification(reminder);
          });
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
          setState(() {
            reminders[index] = updatedReminder;
            _saveReminders();
            _scheduleNotification(updatedReminder);
          });
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
              setState(() {
                reminders.removeAt(index);
                _saveReminders();
                _cancelNotification(reminder);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(int index) {
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

  // Use NotificationService to schedule reminders
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
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No reminders yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Add Reminder'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: reminder.isEnabled ? Colors.red : Colors.grey,
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
                              activeColor: Colors.red,
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
        backgroundColor: Colors.red,
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
  late String _selectedHabitId;
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late TextEditingController _messageController;
  bool _isEnabled = true;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedHabitId = widget.reminder?.habitId ?? widget.habits.first.id;
    _selectedTime = widget.reminder?.time ?? TimeOfDay.now();
    _selectedDays = widget.reminder?.days ?? [1, 2, 3, 4, 5, 6, 7]; // Default to all days
    _messageController = TextEditingController(
      text: widget.reminder?.message ?? 'Time to complete your habit!',
    );
    _isEnabled = widget.reminder?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _validateAndSave() {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reminder = HabitReminder(
      id: widget.reminder?.id ?? const Uuid().v4(),
      habitId: _selectedHabitId,
      time: _selectedTime,
      days: _selectedDays,
      isEnabled: _isEnabled,
      message: _messageController.text.trim(),
    );

    widget.onSave(reminder);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedHabitId,
              decoration: const InputDecoration(
                labelText: 'Habit',
              ),
              items: widget.habits.map((habit) {
                return DropdownMenuItem<String>(
                  value: habit.id,
                  child: Text(habit.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedHabitId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Time:'),
                const Spacer(),
                TextButton(
                  onPressed: _selectTime,
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Days:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: isSelected,
                  onSelected: (_) => _toggleDay(day),
                  selectedColor: Colors.red[100],
                  checkmarkColor: Colors.red,
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Reminder Message',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Enabled:'),
                const Spacer(),
                Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
