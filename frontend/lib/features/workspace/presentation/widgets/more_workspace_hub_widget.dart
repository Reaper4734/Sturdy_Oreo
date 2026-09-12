import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/models/persona_model.dart';
import '../../../../shared/models/workspace_model.dart';

class MoreWorkspaceHubWidget extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;
  final PersonaProfile? profile;
  final ValueChanged<String>? onOpenLabTopic;

  const MoreWorkspaceHubWidget({
    super.key,
    required this.workspace,
    this.profile,
    this.onOpenLabTopic,
  });

  @override
  ConsumerState<MoreWorkspaceHubWidget> createState() => _MoreWorkspaceHubWidgetState();
}

class _MoreWorkspaceHubWidgetState extends ConsumerState<MoreWorkspaceHubWidget> {
  String _selectedSection = 'all'; // 'all', 'persona', 'projects', 'resources', 'assessments'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subject = widget.workspace.subject.isNotEmpty ? widget.workspace.subject : 'Software Engineering';

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 60),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Section Filter Pills
                Row(
                  children: [
                    Icon(Icons.more_horiz_rounded, size: 24, color: colors.accentPrimary),
                    const SizedBox(width: 10),
                    Text(
                      'More Workspace Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.fgPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Subject: $subject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill('all', 'All Tools', Icons.grid_view_rounded, colors),
                      const SizedBox(width: 8),
                      _buildPill('persona', 'Persona / Profile', Icons.badge_outlined, colors),
                      const SizedBox(width: 8),
                      _buildPill('projects', 'Projects & Labs', Icons.terminal_rounded, colors),
                      const SizedBox(width: 8),
                      _buildPill('resources', 'Resources & Docs', Icons.menu_book_outlined, colors),
                      const SizedBox(width: 8),
                      _buildPill('assessments', 'Assessments & Quizzes', Icons.quiz_outlined, colors),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: colors.borderSubtle, thickness: 1.0, height: 1.0),
                const SizedBox(height: 24),

                // 1. Persona / Profile Section
                if (_selectedSection == 'all' || _selectedSection == 'persona') ...[
                  _buildSectionHeader('Persona & Cognitive Profile', Icons.badge_outlined, colors),
                  const SizedBox(height: 14),
                  if (widget.profile != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radar Matrix
                        Expanded(
                          flex: 5,
                          child: _buildRadarChartCard(context, widget.profile!, colors),
                        ),
                        const SizedBox(width: 16),
                        // Persona Badge Card
                        Expanded(
                          flex: 6,
                          child: _buildPersonaBadgeCard(context, widget.profile!, colors),
                        ),
                      ],
                    ),
                  ] else
                    _buildEmptyNotice('Persona profile is being computed for this workspace.', colors),
                  const SizedBox(height: 32),
                ],

                // 2. Projects & Capstones Section
                if (_selectedSection == 'all' || _selectedSection == 'projects') ...[
                  _buildSectionHeader('Practical Projects & Capstones', Icons.terminal_rounded, colors),
                  const SizedBox(height: 14),
                  _buildProjectsGrid(context, subject, colors),
                  const SizedBox(height: 32),
                ],

                // 3. Resources & Documentation Section
                if (_selectedSection == 'all' || _selectedSection == 'resources') ...[
                  _buildSectionHeader('Curated Resources & Documentation', Icons.menu_book_outlined, colors),
                  const SizedBox(height: 14),
                  _buildResourcesGrid(context, subject, colors),
                  const SizedBox(height: 32),
                ],

                // 4. Assessments & Quizzes Section
                if (_selectedSection == 'all' || _selectedSection == 'assessments') ...[
                  _buildSectionHeader('Assessments & Mastery Checkpoints', Icons.quiz_outlined, colors),
                  const SizedBox(height: 14),
                  _buildAssessmentsGrid(context, subject, colors),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String id, String label, IconData icon, AppColorsExtension colors) {
    final isSelected = _selectedSection == id;
    return InkWell(
      onTap: () => setState(() => _selectedSection = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.12) : colors.bgActivityBar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colors.accentPrimary : colors.fgSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.accentPrimary : colors.fgPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AppColorsExtension colors) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.accentPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.fgPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChartCard(BuildContext context, PersonaProfile profile, AppColorsExtension colors) {
    final m = profile.metrics;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_outlined, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cognitive Radar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.fgPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: colors.accentPrimary.withValues(alpha: 0.18),
                    borderColor: colors.accentPrimary,
                    entryRadius: 2.5,
                    borderWidth: 2,
                    dataEntries: [
                      RadarEntry(value: m.visualization * 100),
                      RadarEntry(value: m.applied * 100),
                      RadarEntry(value: m.theoretical * 100),
                      RadarEntry(value: m.pacing * 100),
                      RadarEntry(value: m.logic * 100),
                    ],
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBorderData: BorderSide(color: colors.borderSubtle, width: 1),
                gridBorderData: BorderSide(color: colors.borderSubtle, width: 0.6),
                tickBorderData: const BorderSide(color: Colors.transparent),
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(text: 'Visual (${(m.visualization * 100).toInt()}%)');
                    case 1:
                      return RadarChartTitle(text: 'Practical (${(m.applied * 100).toInt()}%)');
                    case 2:
                      return RadarChartTitle(text: 'Theory (${(m.theoretical * 100).toInt()}%)');
                    case 3:
                      return RadarChartTitle(text: 'Pacing (${(m.pacing * 100).toInt()}%)');
                    case 4:
                      return RadarChartTitle(text: 'Logic (${(m.logic * 100).toInt()}%)');
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaBadgeCard(BuildContext context, PersonaProfile profile, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.accentEmerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.accentEmerald.withValues(alpha: 0.3)),
            ),
            child: Text(
              'COGNITIVE PERSONA',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentEmerald),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.fgPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            profile.subtitle,
            style: TextStyle(fontSize: 12, color: colors.accentPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            profile.summary,
            style: TextStyle(fontSize: 12, height: 1.4, color: colors.fgSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.traits.map((trait) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgActivityBar,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 12, color: colors.accentEmerald),
                    const SizedBox(width: 4),
                    Text(trait, style: TextStyle(fontSize: 11, color: colors.fgPrimary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid(BuildContext context, String subject, AppColorsExtension colors) {
    final projects = [
      {
        'title': 'High-Throughput Concurrent Engine',
        'desc': 'Build a non-blocking queue and thread pool worker model.',
        'difficulty': 'Advanced',
        'status': 'In Progress',
        'topic': 'Concurrency',
      },
      {
        'title': 'Custom LRU Cache with Generics',
        'desc': 'Design an efficient hash map + doubly linked list cache.',
        'difficulty': 'Intermediate',
        'status': 'Available',
        'topic': 'Data Structures',
      },
      {
        'title': 'REST Microservice & JSON Parser',
        'desc': 'Construct an HTTP service with strict schema validation.',
        'difficulty': 'Intermediate',
        'status': 'Available',
        'topic': 'Networking',
      },
    ];

    return Row(
      children: projects.map((p) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p['difficulty']!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentPrimary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      p['status']!,
                      style: TextStyle(fontSize: 10, color: colors.fgSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p['title']!,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p['desc']!,
                  style: TextStyle(fontSize: 11, color: colors.fgSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    if (widget.onOpenLabTopic != null) {
                      widget.onOpenLabTopic!(p['topic']!);
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        'Launch in Lab',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accentPrimary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: colors.accentPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResourcesGrid(BuildContext context, String subject, AppColorsExtension colors) {
    final resources = [
      {
        'title': '$subject Specification & Standards',
        'type': 'Official Spec',
        'icon': Icons.menu_book_rounded,
        'badge': 'Core Doc',
      },
      {
        'title': 'Concurrency & Memory Model Reference',
        'type': 'Deep Dive',
        'icon': Icons.memory_rounded,
        'badge': 'Architecture',
      },
      {
        'title': 'Best Practices & Design Patterns Catalog',
        'type': 'Guide',
        'icon': Icons.schema_outlined,
        'badge': 'Patterns',
      },
    ];

    return Row(
      children: resources.map((r) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.bgActivityBar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Icon(r['icon'] as IconData, size: 18, color: colors.accentPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['title'] as String,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r['type'] as String,
                        style: TextStyle(fontSize: 11, color: colors.fgSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssessmentsGrid(BuildContext context, String subject, AppColorsExtension colors) {
    final assessments = [
      {
        'title': '$subject Core Mastery Survey',
        'questions': '10 Questions',
        'time': '~8 mins',
        'score': '95% Passed',
      },
      {
        'title': 'Advanced Memory Management Quiz',
        'questions': '8 Questions',
        'time': '~6 mins',
        'score': 'Ready',
      },
      {
        'title': 'System Design & Algorithms Checkpoint',
        'questions': '12 Questions',
        'time': '~12 mins',
        'score': 'Ready',
      },
    ];

    return Row(
      children: assessments.map((a) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz_outlined, size: 16, color: colors.accentEmerald),
                    const SizedBox(width: 6),
                    Text(
                      a['score']!,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accentEmerald),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  a['title']!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${a['questions']} • ${a['time']}',
                  style: TextStyle(fontSize: 11, color: colors.fgSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyNotice(String msg, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Center(
        child: Text(msg, style: TextStyle(color: colors.fgSecondary, fontSize: 12)),
      ),
    );
  }
}
