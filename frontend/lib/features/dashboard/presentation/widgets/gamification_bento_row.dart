import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/persona_model.dart';

class GamificationBentoRow extends StatelessWidget {
  final int streakDays;
  final int completedSessions;
  final int weeklyTarget;
  final int masteredConcepts;
  final int totalConcepts;
  final int flashcardCount;
  final PersonaProfile? persona;

  const GamificationBentoRow({
    super.key,
    this.streakDays = 0,
    this.completedSessions = 0,
    this.weeklyTarget = 5,
    this.masteredConcepts = 0,
    this.totalConcepts = 0,
    this.flashcardCount = 0,
    this.persona,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

        if (isMobile) {
          return Column(
            children: [
              _buildStreakCard(context, colors),
              const SizedBox(height: 12),
              _buildWeeklyProgressCard(context, colors),
              const SizedBox(height: 12),
              _buildMasteryCard(context, colors),
              const SizedBox(height: 12),
              _buildCognitiveStyleCard(context, colors),
            ],
          );
        }

        if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStreakCard(context, colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWeeklyProgressCard(context, colors)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMasteryCard(context, colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCognitiveStyleCard(context, colors)),
                ],
              ),
            ],
          );
        }

        // Desktop 4-card Row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStreakCard(context, colors)),
            const SizedBox(width: 12),
            Expanded(child: _buildWeeklyProgressCard(context, colors)),
            const SizedBox(width: 12),
            Expanded(child: _buildMasteryCard(context, colors)),
            const SizedBox(width: 12),
            Expanded(child: _buildCognitiveStyleCard(context, colors)),
          ],
        );
      },
    );
  }

  // 1. Learning Streak Card
  Widget _buildStreakCard(BuildContext context, AppColorsExtension colors) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun

    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Learning Streak',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streakDays days strong! 🔥',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
              const SizedBox(height: 8),
              // 7-day strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(days.length, (index) {
                  final isDayActive = streakDays > 0 && index < todayWeekday;
                  final isToday = index == (todayWeekday - 1);

                  return Column(
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? colors.accentPrimary : colors.fgSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDayActive
                              ? const Color(0xFFF97316) // Amber/Orange dot
                              : (isToday ? colors.borderSubtle : colors.bgActivityBar),
                          border: isToday ? Border.all(color: const Color(0xFFF97316), width: 1.5) : null,
                        ),
                        child: isDayActive
                            ? const Icon(Icons.check, size: 9, color: Colors.white)
                            : null,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
          Text(
            streakDays > 0 ? 'Consistent momentum' : 'Start your streak today',
            style: TextStyle(fontSize: 10, color: colors.fgSecondary),
          ),
        ],
      ),
    );
  }

  // 2. Weekly Progress Card
  Widget _buildWeeklyProgressCard(BuildContext context, AppColorsExtension colors) {
    final progress = weeklyTarget > 0 ? (completedSessions / weeklyTarget).clamp(0.0, 1.0) : 0.0;
    final remaining = (weeklyTarget - completedSessions).clamp(0, weeklyTarget);

    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Text(
                'Weekly Progress',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedSessions / $weeklyTarget sessions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : 0.05,
                  minHeight: 6,
                  backgroundColor: colors.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                remaining > 0 ? '$remaining sessions to reach goal' : 'Weekly goal achieved!',
                style: TextStyle(fontSize: 10, color: colors.fgSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Concept Mastery & Flashcards Card
  Widget _buildMasteryCard(BuildContext context, AppColorsExtension colors) {
    final masteryPct = totalConcepts > 0 ? (masteredConcepts / totalConcepts).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 14, color: const Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Concept Mastery',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totalConcepts > 0
                    ? '$masteredConcepts / $totalConcepts mastered'
                    : '$flashcardCount flashcards ready',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: masteryPct > 0 ? masteryPct : 0.1,
                  minHeight: 6,
                  backgroundColor: colors.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.style_outlined, size: 12, color: colors.fgSecondary),
              const SizedBox(width: 4),
              Text(
                '$flashcardCount flashcard decks active',
                style: TextStyle(fontSize: 10, color: colors.fgSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Cognitive Persona Style Card
  Widget _buildCognitiveStyleCard(BuildContext context, AppColorsExtension colors) {
    final title = persona?.title.isNotEmpty == true ? persona!.title : 'Adaptive Learner';
    final traits = persona?.traits.isNotEmpty == true
        ? persona!.traits.take(2).join(' • ')
        : 'Visual • Practical Execution';

    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 14, color: const Color(0xFF818CF8)),
              const SizedBox(width: 6),
              Text(
                'Cognitive Style',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                traits,
                style: TextStyle(fontSize: 11, color: colors.fgSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 12, color: const Color(0xFF818CF8)),
              const SizedBox(width: 4),
              Text(
                'Personalized pacing enabled',
                style: TextStyle(fontSize: 10, color: colors.fgSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
