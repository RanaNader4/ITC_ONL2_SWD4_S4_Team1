import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/habit.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  
  List<Achievement> achievements = [];
  
  AchievementService._internal();
  
  Future<void> init() async {
    await _loadAchievements();
  }
  
  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getStringList('achievements');

    if (achievementsJson == null) {
      // First time - initialize with default achievements
      achievements = AchievementList.getDefaultAchievements();
      await _saveAchievements();
    } else {
      achievements = achievementsJson
          .map((json) => Achievement.fromJson(jsonDecode(json)))
          .toList();
    }
  }
  
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = achievements
        .map((achievement) => jsonEncode(achievement.toJson()))
        .toList();
    await prefs.setStringList('achievements', achievementsJson);
  }
  
  Future<Achievement?> checkAndUnlockAchievements(List<Habit> activeHabits, List<Habit> completedHabits) async {
    if (achievements.isEmpty) {
      await _loadAchievements();
    }
    
    Achievement? latestUnlocked;
    bool hasChanges = false;
    
    // Check for first habit achievement
    final firstHabitAchievement = achievements.firstWhere(
      (a) => a.id == 'first_habit',
      orElse: () => Achievement(
        id: 'first_habit',
        title: 'First Steps',
        description: 'Create your first habit',
        iconPath: 'assets/images/achievements/first_habit.svg',
      ),
    );
    
    if (!firstHabitAchievement.isUnlocked && (activeHabits.isNotEmpty || completedHabits.isNotEmpty)) {
      final updatedAchievement = firstHabitAchievement.copyWith(
        isUnlocked: true,
        unlockedDate: DateTime.now(),
      );
      
      final index = achievements.indexWhere((a) => a.id == 'first_habit');
      if (index >= 0) {
        achievements[index] = updatedAchievement;
      } else {
        achievements.add(updatedAchievement);
      }
      
      latestUnlocked = updatedAchievement;
      hasChanges = true;
    }
    
    // Check for completed habits achievements
    final completedCount = completedHabits.length;
    
    if (completedCount >= 5) {
      final complete5Achievement = achievements.firstWhere(
        (a) => a.id == 'complete_5_habits',
        orElse: () => Achievement(
          id: 'complete_5_habits',
          title: 'Habit Hunter',
          description: 'Complete 5 different habits',
          iconPath: 'assets/images/achievements/complete_5.svg',
        ),
      );
      
      if (!complete5Achievement.isUnlocked) {
        final updatedAchievement = complete5Achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        );
        
        final index = achievements.indexWhere((a) => a.id == 'complete_5_habits');
        if (index >= 0) {
          achievements[index] = updatedAchievement;
        } else {
          achievements.add(updatedAchievement);
        }
        
        latestUnlocked = updatedAchievement;
        hasChanges = true;
      }
    }
    
    if (completedCount >= 10) {
      final complete10Achievement = achievements.firstWhere(
        (a) => a.id == 'complete_10_habits',
        orElse: () => Achievement(
          id: 'complete_10_habits',
          title: 'Habit Hero',
          description: 'Complete 10 different habits',
          iconPath: 'assets/images/achievements/complete_10.svg',
        ),
      );
      
      if (!complete10Achievement.isUnlocked) {
        final updatedAchievement = complete10Achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        );
        
        final index = achievements.indexWhere((a) => a.id == 'complete_10_habits');
        if (index >= 0) {
          achievements[index] = updatedAchievement;
        } else {
          achievements.add(updatedAchievement);
        }
        
        latestUnlocked = updatedAchievement;
        hasChanges = true;
      }
    }
    
    // Check for streak achievements
    final maxStreak = [...activeHabits, ...completedHabits].fold<int>(
      0,
      (max, habit) => habit.streak > max ? habit.streak : max,
    );
    
    if (maxStreak >= 7) {
      final streak7Achievement = achievements.firstWhere(
        (a) => a.id == 'habit_streak_7',
        orElse: () => Achievement(
          id: 'habit_streak_7',
          title: 'Week Warrior',
          description: 'Complete a habit for 7 consecutive days',
          iconPath: 'assets/images/achievements/streak_7.svg',
        ),
      );
      
      if (!streak7Achievement.isUnlocked) {
        final updatedAchievement = streak7Achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        );
        
        final index = achievements.indexWhere((a) => a.id == 'habit_streak_7');
        if (index >= 0) {
          achievements[index] = updatedAchievement;
        } else {
          achievements.add(updatedAchievement);
        }
        
        latestUnlocked = updatedAchievement;
        hasChanges = true;
      }
    }
    
    if (maxStreak >= 30) {
      final streak30Achievement = achievements.firstWhere(
        (a) => a.id == 'habit_streak_30',
        orElse: () => Achievement(
          id: 'habit_streak_30',
          title: 'Monthly Master',
          description: 'Complete a habit for 30 consecutive days',
          iconPath: 'assets/images/achievements/streak_30.svg',
        ),
      );
      
      if (!streak30Achievement.isUnlocked) {
        final updatedAchievement = streak30Achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        );
        
        final index = achievements.indexWhere((a) => a.id == 'habit_streak_30');
        if (index >= 0) {
          achievements[index] = updatedAchievement;
        } else {
          achievements.add(updatedAchievement);
        }
        
        latestUnlocked = updatedAchievement;
        hasChanges = true;
      }
    }
    
    // Check for categories achievement
    final categories = [...activeHabits, ...completedHabits]
        .map((habit) => habit.categoryId)
        .toSet();
    
    if (categories.length >= 3) {
      final categories3Achievement = achievements.firstWhere(
        (a) => a.id == 'categories_3',
        orElse: () => Achievement(
          id: 'categories_3',
          title: 'Diversified',
          description: 'Create habits in 3 different categories',
          iconPath: 'assets/images/achievements/categories_3.svg',
        ),
      );
      
      if (!categories3Achievement.isUnlocked) {
        final updatedAchievement = categories3Achievement.copyWith(
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        );
        
        final index = achievements.indexWhere((a) => a.id == 'categories_3');
        if (index >= 0) {
          achievements[index] = updatedAchievement;
        } else {
          achievements.add(updatedAchievement);
        }
        
        latestUnlocked = updatedAchievement;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveAchievements();
    }
    
    return latestUnlocked;
  }
  
  Future<List<Achievement>> getAchievements() async {
    if (achievements.isEmpty) {
      await _loadAchievements();
    }
    return achievements;
  }
}
