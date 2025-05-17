import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/habit.dart';

class ChartsPage extends StatelessWidget {
  final List<Habit> completedHabits;
  
  const ChartsPage({super.key, required this.completedHabits});

  @override
  Widget build(BuildContext context) {
    final activeHabits = ModalRoute.of(context)!.settings.arguments as List<Habit>;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-dependent colors for chart elements
    final Color axisLabelColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color gridLineColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
    final Color barGoalColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
    final Color barProgressColor = isDarkMode ? Colors.green.shade300 : Colors.green;
    final Color barCompletedColor = isDarkMode ? Colors.redAccent[100]! : Colors.redAccent;
    final Color legendTextColor = Theme.of(context).colorScheme.onSurface;


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Habit Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeHabits.isNotEmpty) ...[  
                Text(
                  'Active Habits Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.transparent,
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(activeHabits),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDarkMode ? Colors.grey[700] : Colors.blueGrey[50],
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String habitName = activeHabits[group.x.toInt()].name;
                            String value = rod.toY.round().toString();
                            String type = rodIndex == 0 ? "Goal" : "Progress";
                            return BarTooltipItem(
                              '$habitName\n$type: $value',
                              TextStyle(color: isDarkMode? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            );
                          }
                        )
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(value.toInt().toString(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: axisLabelColor)),
                              );
                            }
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= activeHabits.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  activeHabits[index].name,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: axisLabelColor),
                                  overflow: TextOverflow.ellipsis,
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
                        border: Border(
                          left: BorderSide(color: gridLineColor),
                          bottom: BorderSide(color: gridLineColor),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getHorizontalInterval(activeHabits),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: gridLineColor,
                            strokeWidth: 0.5,
                          );
                        }
                      ),
                      barGroups: activeHabits.asMap().entries.map((entry) {
                        final index = entry.key;
                        final habit = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: habit.goal.toDouble(),
                              color: barGoalColor, 
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: habit.progress.toDouble(),
                              color: barProgressColor, 
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.square, color: barGoalColor, size: 16),
                    const SizedBox(width: 4),
                    Text('Goal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: legendTextColor)),
                    const SizedBox(width: 20),
                    Icon(Icons.square, color: barProgressColor, size: 16),
                    const SizedBox(width: 4),
                    Text('Current Progress', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: legendTextColor)),
                  ],
                ),
                const SizedBox(height: 30),
              ],            
              if (completedHabits.isNotEmpty) ...[  
                Text(
                  'Completed Habits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.transparent,
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(completedHabits),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDarkMode ? Colors.grey[700] : Colors.blueGrey[50],
                           getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String habitName = completedHabits[group.x.toInt()].name;
                            String value = rod.toY.round().toString();
                            return BarTooltipItem(
                              '$habitName\nCompleted: $value',
                              TextStyle(color: isDarkMode? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            );
                          }
                        )
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(value.toInt().toString(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: axisLabelColor)),
                              );
                            }
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= completedHabits.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  completedHabits[index].name,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: axisLabelColor),
                                  overflow: TextOverflow.ellipsis,
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
                        border: Border(
                          left: BorderSide(color: gridLineColor),
                          bottom: BorderSide(color: gridLineColor),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getHorizontalInterval(completedHabits),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: gridLineColor,
                            strokeWidth: 0.5,
                          );
                        }
                      ),
                      barGroups: completedHabits.asMap().entries.map((entry) {
                        final index = entry.key;
                        final habit = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: habit.goal.toDouble(),
                              color: barCompletedColor, 
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
              ],
              
              if (activeHabits.isEmpty && completedHabits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Text(
                      'No habits to display yet.\nAdd some habits to track your progress!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxY(List<Habit> habits) {
    double maxY = 1;
    for (var habit in habits) {
      if (habit.goal > maxY) maxY = habit.goal.toDouble();
      if (habit.progress > maxY) maxY = habit.progress.toDouble();
    }
    return maxY + (maxY * 0.1);
  }

  double _getHorizontalInterval(List<Habit> habits) {
    double maxY = 1;
    for (var habit in habits) {
      if (habit.goal > maxY) maxY = habit.goal.toDouble();
      if (habit.progress > maxY) maxY = habit.progress.toDouble();
    }
    if (maxY <= 10) return 1;
    if (maxY <= 20) return 2;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    if (maxY <= 200) return 20;
    return (maxY / 5).roundToDouble();
  }
}
