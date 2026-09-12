import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/http_dashboard_repository.dart';

class DashboardHeaderWidget extends StatelessWidget {
  final String learnerName;
  final int streakDays;
  final int completedSessions;
  final int weeklyTarget;
  final VoidCallback? onNotificationTap;

  const DashboardHeaderWidget({
    super.key,
    required this.learnerName,
    this.streakDays = 0,
    this.completedSessions = 0,
    this.weeklyTarget = 5,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final greeting = HttpDashboardRepository.getTimeGreeting();
    final displayName = learnerName.isNotEmpty ? learnerName : 'Learner';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(greeting, displayName, colors),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStreakPill(context, colors),
                    const SizedBox(width: 10),
                    _buildWeeklyGoalPill(context, colors),
                    const SizedBox(width: 10),
                    _buildNotificationButton(context, colors),
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Greeting & Subtitle
            Expanded(
              child: _buildGreeting(greeting, displayName, colors),
            ),

            // Right Header Metrics & Notification
            Row(
              children: [
                _buildStreakPill(context, colors),
                const SizedBox(width: 12),
                _buildWeeklyGoalPill(context, colors),
                const SizedBox(width: 12),
                _buildNotificationButton(context, colors),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGreeting(String greeting, String name, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$greeting, $name!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.fgPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            const Text('👋', style: TextStyle(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Keep learning. Keep building.',
          style: TextStyle(
            fontSize: 13,
            color: colors.fgSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakPill(BuildContext context, AppColorsExtension colors) {
    // 7-day strip (M T W T F S S)
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                '$streakDays Day Streak',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(days.length, (index) {
              final isDayActive = streakDays > 0 && index < todayWeekday;
              final isToday = index == (todayWeekday - 1);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Column(
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
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDayActive
                            ? const Color(0xFF38BDF8) // Blue active dot
                            : (isToday ? colors.accentPrimary : colors.borderSubtle),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalPill(BuildContext context, AppColorsExtension colors) {
    final progress = weeklyTarget > 0 ? (completedSessions / weeklyTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Weekly Goal',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.fgSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedSessions / $weeklyTarget ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                ),
              ),
              Text(
                'sessions',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.fgSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.borderSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, AppColorsExtension colors) {
    return InkWell(
      onTap: onNotificationTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Icon(
          Icons.notifications_none_rounded,
          size: 20,
          color: colors.fgPrimary,
        ),
      ),
    );
  }
}
