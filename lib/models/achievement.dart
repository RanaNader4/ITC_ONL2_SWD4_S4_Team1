import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    this.isUnlocked = false,
    this.unlockedDate,
  });
  
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconPath': iconPath,
    'isUnlocked': isUnlocked,
    'unlockedDate': unlockedDate?.millisecondsSinceEpoch,
  };
  
  static Achievement fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    iconPath: json['iconPath'],
    isUnlocked: json['isUnlocked'],
    unlockedDate: json['unlockedDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['unlockedDate']) 
        : null,
  );
}

class AchievementList {
  static List<Achievement> getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_habit',
        title: 'First Steps',
        description: 'Create your first habit',
        iconPath: 'assets/images/achievements/first_habit.svg',
      ),
      Achievement(
        id: 'habit_streak_7',
        title: 'Week Warrior',
        description: 'Complete a habit for 7 consecutive days',
        iconPath: 'assets/images/achievements/streak_7.svg',
      ),
      Achievement(
        id: 'habit_streak_30',
        title: 'Monthly Master',
        description: 'Complete a habit for 30 consecutive days',
        iconPath: 'assets/images/achievements/streak_30.svg',
      ),
      Achievement(
        id: 'complete_5_habits',
        title: 'Habit Hunter',
        description: 'Complete 5 different habits',
        iconPath: 'assets/images/achievements/complete_5.svg',
      ),
      Achievement(
        id: 'complete_10_habits',
        title: 'Habit Hero',
        description: 'Complete 10 different habits',
        iconPath: 'assets/images/achievements/complete_10.svg',
      ),
      Achievement(
        id: 'categories_3',
        title: 'Diversified',
        description: 'Create habits in 3 different categories',
        iconPath: 'assets/images/achievements/categories_3.svg',
      ),
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: 'Complete all habits for an entire week',
        iconPath: 'assets/images/achievements/perfect_week.svg',
      ),
    ];
  }
}
