import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/habit.dart';

class ChartsPage extends StatelessWidget {
  final List<Habit> completedHabits;
  
  const ChartsPage({super.key, required this.completedHabits});

  @override
  Widget build(BuildContext context) {
    final activeHabits = ModalRoute.of(context)!.settings.arguments as List<Habit>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Progress'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeHabits.isNotEmpty) ...[  
              const Text(
                'Active Habits Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(activeHabits),
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= activeHabits.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                activeHabits[index].name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black),
                        bottom: BorderSide(color: Colors.black),
                      ),
                    ),
                    barGroups: activeHabits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habit = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: habit.goal.toDouble(),
                            color: Colors.blue,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: habit.progress.toDouble(),
                            color: Colors.green,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.square, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Text('Goal'),
                  SizedBox(width: 20),
                  Icon(Icons.square, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Current Progress'),
                ],
              ),
              const SizedBox(height: 30),
            ],
            
            if (completedHabits.isNotEmpty) ...[  
              const Text(
                'Completed Habits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(completedHabits),
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= completedHabits.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                completedHabits[index].name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black),
                        bottom: BorderSide(color: Colors.black),
                      ),
                    ),
                    barGroups: completedHabits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habit = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: habit.goal.toDouble(),
                            color: Colors.redAccent,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            
            if (activeHabits.isEmpty && completedHabits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text(
                    'No habits to display yet.\nAdd some habits to track your progress!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<Habit> habits) {
    double maxY = 1;
    for (var habit in habits) {
      if (habit.goal > maxY) maxY = habit.goal.toDouble();
    }
    return maxY + 2;
  }

}
