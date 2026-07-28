import 'package:flutter/material.dart';

import '../data/lessons_data.dart';
import '../logic/activity_result_service.dart';
import '../models/activity_result.dart';
import '../models/lesson.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/responsive_container.dart';

class LessonHistoryScreen extends StatefulWidget {
  const LessonHistoryScreen({super.key});

  @override
  State<LessonHistoryScreen> createState() => _LessonHistoryScreenState();
}

class _LessonHistoryScreenState extends State<LessonHistoryScreen> {
  List<ActivityResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final results = await ActivityResultService.getActivityResults();

    final Map<String, List<ActivityResult>> groupedByLesson = {};
    for (final result in results) {
      if (result.lessonId.isNotEmpty) {
        groupedByLesson.putIfAbsent(result.lessonId, () => []).add(result);
      }
    }

    List<MapEntry<String, List<ActivityResult>>> entries = groupedByLesson
        .entries
        .toList();

    entries.sort((a, b) {
      final aTime = a.value.last.timestamp;
      final bTime = b.value.last.timestamp;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: ResponsiveContainer(
        maxWidth: 700,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.scale(context, 20, 24, 28)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.appColors.surfaceVariant.withAlpha(20),
                  context.appColors.surfaceVariant.withAlpha(5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: Responsive.scale(context, 60, 70, 80),
              color: context.appColors.textTertiary,
            ),
          ),
          SizedBox(height: Responsive.scale(context, 16, 20, 24)),
          Text(
            'Sin historial todavía',
            style: TextStyle(
              fontSize: Responsive.scale(context, 18, 20, 22),
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.scale(context, 8, 10, 12)),
          Text(
            'Completa lecciones para ver tu progreso aquí',
            style: TextStyle(
              fontSize: Responsive.scale(context, 13, 14, 15),
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final Map<String, List<ActivityResult>> groupedByLesson = {};
    for (final result in _results) {
      groupedByLesson.putIfAbsent(result.lessonId, () => []).add(result);
    }

    final entries = groupedByLesson.entries.toList();

    entries.sort((a, b) {
      final aTime = a.value.last.timestamp;
      final bTime = b.value.last.timestamp;
      return bTime.compareTo(aTime);
    });

    return ListView.builder(
      padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final lessonResults = entry.value;
        final lessonId = entry.key;

        final totalAttempts = lessonResults.length;
        final correctAttempts = lessonResults.where((r) => r.isCorrect).length;
        final accuracy = totalAttempts > 0
            ? (correctAttempts / totalAttempts * 100).round()
            : 0;
        final lastActivity = lessonResults.last.timestamp;

        Lesson? lesson;
        try {
          lesson = lessonsList.firstWhere((l) => l.id == lessonId);
        } catch (_) {
          lesson = null;
        }

        return Container(
          margin: EdgeInsets.only(bottom: Responsive.scale(context, 12, 14, 16)),
          padding: EdgeInsets.all(Responsive.scale(context, 14, 16, 18)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
            ),
            boxShadow: [
              BoxShadow(
                color: context.appColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: Responsive.scale(context, 48, 52, 56),
                height: Responsive.scale(context, 48, 52, 56),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(25),
                      AppColors.primary.withAlpha(10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    lesson?.title.isNotEmpty == true
                        ? lesson!.title[0].toUpperCase()
                        : lessonId.replaceAll('lesson_', '')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 18, 20, 22),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.scale(context, 12, 14, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson?.title ?? 'Lección ${lessonId.replaceAll("lesson_", "")}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.scale(context, 15, 16, 17),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(lastActivity),
                      style: TextStyle(
                        fontSize: Responsive.scale(context, 12, 13, 14),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.scale(context, 8, 10, 12),
                            vertical: Responsive.scale(context, 4, 5, 6),
                          ),
                          decoration: BoxDecoration(
                            color: accuracy >= 70
                                ? Colors.green.withAlpha(20)
                                : Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                accuracy >= 70 ? Icons.check_circle : Icons.info_outline,
                                size: Responsive.scale(context, 14, 15, 16),
                                color: accuracy >= 70
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$accuracy% acierto',
                                style: TextStyle(
                                  fontSize: Responsive.scale(context, 12, 13, 14),
                                  color: accuracy >= 70
                                      ? Colors.green[600]
                                      : Colors.orange[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: Responsive.scale(context, 8, 10, 12)),
                        Text(
                          '$totalAttempts intentos',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 12, 13, 14),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (accuracy >= 70)
                Container(
                  padding: EdgeInsets.all(Responsive.scale(context, 6, 8, 10)),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.green[600],
                    size: Responsive.scale(context, 20, 22, 24),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
