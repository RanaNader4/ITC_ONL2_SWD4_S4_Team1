import 'package:flutter/material.dart';

class HabitReminder {
  final String id;
  final String habitId;
  final TimeOfDay time;
  final List<int> days;
  final bool isEnabled;
  final String message;
  
  HabitReminder({
    required this.id,
    required this.habitId,
    required this.time,
    required this.days,
    this.isEnabled = true,
    this.message = 'Time to complete your habit!',
  });
  
  HabitReminder copyWith({
    String? id,
    String? habitId,
    TimeOfDay? time,
    List<int>? days,
    bool? isEnabled,
    String? message,
  }) {
    return HabitReminder(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      time: time ?? this.time,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      message: message ?? this.message,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'hour': time.hour,
    'minute': time.minute,
    'days': days,
    'isEnabled': isEnabled,
    'message': message,
  };
  
  static HabitReminder fromJson(Map<String, dynamic> json) => HabitReminder(
    id: json['id'],
    habitId: json['habitId'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    days: List<int>.from(json['days']),
    isEnabled: json['isEnabled'],
    message: json['message'],
  );
  
  String get timeString => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  
  String get daysString {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    if (days.length == 0) return 'Never';
    
    return days.map((day) => dayNames[day - 1]).join(', ');
  }
}
