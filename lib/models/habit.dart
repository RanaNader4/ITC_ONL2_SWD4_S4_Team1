import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';
import 'reminder.dart';

class Habit {
  final String id;
  String name;
  int progress;
  int goal;
  String categoryId;
  List<HabitReminder> reminders;
  DateTime createdAt;
  DateTime? lastCompletedAt;
  int streak;
  
  Habit({
    String? id,
    required this.name, 
    this.progress = 0, 
    required this.goal,
    this.categoryId = 'other',
    List<HabitReminder>? reminders,
    DateTime? createdAt,
    this.lastCompletedAt,
    this.streak = 0,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.reminders = reminders ?? [],
    this.createdAt = createdAt ?? DateTime.now();
  
  Habit copyWith({
    String? name,
    int? progress,
    int? goal,
    String? categoryId,
    List<HabitReminder>? reminders,
    DateTime? lastCompletedAt,
    int? streak,
  }) {
    return Habit(
      id: this.id,
      name: name ?? this.name,
      progress: progress ?? this.progress,
      goal: goal ?? this.goal,
      categoryId: categoryId ?? this.categoryId,
      reminders: reminders ?? this.reminders,
      createdAt: this.createdAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      streak: streak ?? this.streak,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'progress': progress,
    'goal': goal,
    'categoryId': categoryId,
    'reminders': reminders.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastCompletedAt': lastCompletedAt?.millisecondsSinceEpoch,
    'streak': streak,
  };
  
  static Habit fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    progress: json['progress'],
    goal: json['goal'],
    categoryId: json['categoryId'] ?? 'other',
    reminders: json['reminders'] != null 
        ? List<HabitReminder>.from(
            json['reminders'].map((x) => HabitReminder.fromJson(x))
          )
        : [],
    createdAt: json['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
        : DateTime.now(),
    lastCompletedAt: json['lastCompletedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['lastCompletedAt']) 
        : null,
    streak: json['streak'] ?? 0,
  );
  
  static Habit fromOldHabit(Habit oldHabit) {
    return Habit(
      name: oldHabit.name,
      progress: oldHabit.progress,
      goal: oldHabit.goal,
    );
  }
  
  double get progressPercentage => progress / goal;
  
  bool get isCompleted => progress >= goal;
}
