import 'package:flutter/material.dart';

class HabitCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  
  HabitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconCodePoint': icon.codePoint,
    'colorValue': color.value,
  };
  
  static HabitCategory fromJson(Map<String, dynamic> json) => HabitCategory(
    id: json['id'],
    name: json['name'],
    icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
    color: Color(json['colorValue']),
  );
}

class CategoryList {
  static List<HabitCategory> getDefaultCategories() {
    return [
      HabitCategory(
        id: 'health',
        name: 'Health',
        icon: Icons.favorite,
        color: Colors.red,
      ),
      HabitCategory(
        id: 'fitness',
        name: 'Fitness',
        icon: Icons.fitness_center,
        color: Colors.orange,
      ),
      HabitCategory(
        id: 'productivity',
        name: 'Productivity',
        icon: Icons.work,
        color: Colors.blue,
      ),
      HabitCategory(
        id: 'learning',
        name: 'Learning',
        icon: Icons.school,
        color: Colors.purple,
      ),
      HabitCategory(
        id: 'mindfulness',
        name: 'Mindfulness',
        icon: Icons.self_improvement,
        color: Colors.teal,
      ),
      HabitCategory(
        id: 'social',
        name: 'Social',
        icon: Icons.people,
        color: Colors.pink,
      ),
      HabitCategory(
        id: 'other',
        name: 'Other',
        icon: Icons.more_horiz,
        color: Colors.grey,
      ),
    ];
  }
}
