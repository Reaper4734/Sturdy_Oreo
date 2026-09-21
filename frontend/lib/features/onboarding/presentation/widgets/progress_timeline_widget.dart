import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/persona_model.dart';

class ProgressTimelineWidget extends StatelessWidget {
  final List<BlueprintNode> nodes;
  final ValueChanged<String> onSelectModule;

  const ProgressTimelineWidget({
    super.key,
    required this.nodes,
    required this.onSelectModule,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.bgCanvas,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: colors.accentEmerald, size: 22),
              const SizedBox(width: 8),
              Text(
                'Mastery Progress Map (Timeline View)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Top-to-bottom milestone roadmap tracking your active focus, completed modules, and upcoming capstones.',
            style: TextStyle(fontSize: 13, color: colors.fgSecondary),
          ),
          const SizedBox(height: 24),

          // Vertical Rectangular Timeline Cards List
          Expanded(
            child: ListView.builder(
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                final node = nodes[index];
                final isFirst = index == 0;
                final isLast = index == nodes.length - 1;
                final isCompleted = index == 0;
                final isActive = index == 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vertical Line & Circle Status Indicator Column
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 16,
                              color: isFirst ? Colors.transparent : colors.borderSubtle,
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? colors.accentEmerald
                                    : (isActive ? colors.accentEmerald : colors.bgSurface),
                                border: Border.all(
                                  color: isCompleted
                                      ? colors.accentEmerald
                                      : (isActive ? colors.accentEmerald : colors.borderSubtle),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : (isActive ? Icons.play_arrow_rounded : Icons.lock_outline_rounded),
                                size: 12,
                                color: isCompleted || isActive ? Colors.white : colors.fgSecondary,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isLast ? Colors.transparent : colors.borderSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Rectangular Timeline Module Card
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? colors.accentEmerald : colors.borderSubtle,
                              width: isActive ? 1.5 : 1.0,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: colors.accentEmerald.withValues(alpha: 0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.bgElevated,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.borderSubtle),
                                    ),
                                    child: Text(
                                      node.dayRange,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.fgAccent),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? colors.accentEmerald.withValues(alpha: 0.15)
                                          : (isActive ? colors.accentEmerald.withValues(alpha: 0.15) : colors.bgElevated),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isCompleted ? 'MASTERED' : (isActive ? 'ACTIVE FOCUS' : 'UPCOMING'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? colors.accentEmerald
                                            : (isActive ? colors.accentEmerald : colors.fgSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                node.title,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                node.description,
                                style: TextStyle(fontSize: 13, color: colors.fgSecondary),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: node.topics.map((t) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.bgCanvas,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.borderSubtle),
                                    ),
                                    child: Text('# $t', style: TextStyle(fontSize: 11, color: colors.fgSecondary)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: colors.borderSubtle),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  icon: Icon(Icons.play_arrow_rounded, size: 14, color: colors.fgPrimary),
                                  label: Text('Open Learning Lab', style: TextStyle(fontSize: 11, color: colors.fgPrimary)),
                                  onPressed: () => onSelectModule(node.title),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
