import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/achievement.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<Achievement> achievements = [];
  bool isLoading = true;
  late ConfettiController _confettiController;
  Achievement? recentlyUnlocked;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAchievements();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getStringList('achievements');

    if (achievementsJson == null) {
      // First time - initialize with default achievements
      achievements = AchievementList.getDefaultAchievements();
      _saveAchievements();
    } else {
      achievements = achievementsJson
          .map((json) => Achievement.fromJson(jsonDecode(json)))
          .toList();
    }

    // Check for newly unlocked achievements
    final lastVisitTime = prefs.getInt('last_achievements_visit') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Find the most recently unlocked achievement since last visit
    final newlyUnlocked = achievements.where((a) => 
      a.isUnlocked && 
      a.unlockedDate != null && 
      a.unlockedDate!.millisecondsSinceEpoch > lastVisitTime
    ).toList();
    
    if (newlyUnlocked.isNotEmpty) {
      // Sort by unlock date to get the most recent
      newlyUnlocked.sort((a, b) => 
        (b.unlockedDate?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.unlockedDate?.millisecondsSinceEpoch ?? 0)
      );
      
      recentlyUnlocked = newlyUnlocked.first;
      _confettiController.play();
    }
    
    // Update last visit time
    await prefs.setInt('last_achievements_visit', now);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = achievements
        .map((achievement) => jsonEncode(achievement.toJson()))
        .toList();
    await prefs.setStringList('achievements', achievementsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : achievements.isEmpty
                  ? const Center(child: Text('No achievements yet'))
                  : _buildAchievementsList(),
          
          // Confetti animation for newly unlocked achievements
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -Math.pi / 2, // straight up
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
            ),
          ),
          
          // Show newly unlocked achievement popup
          if (recentlyUnlocked != null)
            _buildUnlockedAchievementPopup(),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    // Group achievements by unlocked/locked
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          const Text(
            'Unlocked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...unlockedAchievements.map(_buildAchievementCard),
          const SizedBox(height: 24),
        ],
        
        if (lockedAchievements.isNotEmpty) ...[
          const Text(
            'Locked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...lockedAchievements.map(_buildAchievementCard),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: achievement.isUnlocked ? 4 : 1,
      color: achievement.isUnlocked ? Colors.white : Colors.grey[200],
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: achievement.isUnlocked ? Colors.amber : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: achievement.isUnlocked
              ? SvgPicture.asset(
                  achievement.iconPath,
                  width: 30,
                  height: 30,
                )
              : Icon(
                  Icons.emoji_events,
                  color: Colors.grey[400],
                  size: 30,
                ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: achievement.isUnlocked ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
          ),
        ),
        trailing: achievement.isUnlocked && achievement.unlockedDate != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Unlocked',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${achievement.unlockedDate!.day}/${achievement.unlockedDate!.month}/${achievement.unlockedDate!.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }

  Widget _buildUnlockedAchievementPopup() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Achievement Unlocked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                recentlyUnlocked!.iconPath,
                width: 50,
                height: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              recentlyUnlocked!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recentlyUnlocked!.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  recentlyUnlocked = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}

// Math class for confetti
class Math {
  static const double pi = 3.1415926535897932;
}
