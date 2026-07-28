import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/flashcard_model.dart';
import '../models/learning_lab_model.dart';
import '../models/micro_interview_model.dart';
import '../models/mind_map_model.dart';
import '../models/persona_model.dart';
import '../models/roadmap_model.dart';
import '../models/workspace_model.dart';
import 'mock_flashcard_repository.dart';
import 'mock_interview_repository.dart';
import 'mock_learning_lab_repository.dart';
import 'mock_mind_map_repository.dart';
import 'mock_persona_repository.dart';
import 'workspace_repository.dart';

/// In-memory mock repository pre-seeded with 10 information-first Learning Spaces.
/// /ponytail ceiling: in-memory state resets on app restart.
/// Swap for SqliteWorkspaceRepository or ApiWorkspaceRepository later without UI changes.
class MockWorkspaceRepository implements IWorkspaceRepository {
  static final MockWorkspaceRepository _instance = MockWorkspaceRepository._internal();
  factory MockWorkspaceRepository() => _instance;
  MockWorkspaceRepository._internal();

  final List<WorkspaceModel> _workspaces = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final basePersona = await MockPersonaRepository().getPersonaProfile();
    final baseCluster = await MockMindMapRepository().getSubjectCluster();
    final baseFlashcards = await MockFlashcardRepository().getAllFlashcards();
    final baseCells = await MockLearningLabRepository().getInitialCanvasGrid();
    final baseChat = await MockInterviewRepository().getInitialMessages();

    final now = DateTime.now();

    // 1. Python Backend Engineering
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_python_01',
      title: 'Python Backend Engineering',
      subject: 'Python Architecture',
      difficulty: 'Intermediate',
      activeLearningContext: 'Inheritance',
      progress: 0.40,
      flashcardsCount: 287,
      nodesCount: 18,
      color: const Color(0xFF67E8F9), // Cyan
      openedAgo: const Duration(hours: 2),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 2. React Frontend Engineering
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_react_02',
      title: 'React Frontend Engineering',
      subject: 'Web Architecture',
      difficulty: 'Advanced',
      activeLearningContext: 'State Hooks',
      progress: 0.60,
      flashcardsCount: 340,
      nodesCount: 24,
      color: const Color(0xFF3B82F6), // Blue
      openedAgo: const Duration(days: 1),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 3. Machine Learning Foundations
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_ml_03',
      title: 'Machine Learning Foundations',
      subject: 'Artificial Intelligence',
      difficulty: 'Advanced',
      activeLearningContext: 'Backpropagation',
      progress: 0.30,
      flashcardsCount: 195,
      nodesCount: 22,
      color: const Color(0xFFEF4444), // Rose
      openedAgo: const Duration(days: 7),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 4. Operating Systems
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_os_04',
      title: 'Operating Systems',
      subject: 'Systems & Kernel',
      difficulty: 'Intermediate',
      activeLearningContext: 'Process Scheduling',
      progress: 0.65,
      flashcardsCount: 210,
      nodesCount: 20,
      color: const Color(0xFFF59E0B), // Amber
      openedAgo: const Duration(days: 14),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 5. System Design
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_sysdes_05',
      title: 'System Design',
      subject: 'Distributed Systems',
      difficulty: 'Advanced',
      activeLearningContext: 'CAP Theorem & Paxos',
      progress: 0.28,
      flashcardsCount: 195,
      nodesCount: 22,
      color: const Color(0xFFEF4444), // Rose
      openedAgo: const Duration(days: 30),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 6. Java Collections & Streams
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_java_06',
      title: 'Java Collections & Streams',
      subject: 'Enterprise Backend',
      difficulty: 'Intermediate',
      activeLearningContext: 'ConcurrentHashMap',
      progress: 0.55,
      flashcardsCount: 180,
      nodesCount: 16,
      color: const Color(0xFFF97316), // Orange
      openedAgo: const Duration(days: 3),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 7. React & Next.js App Router
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_react_07',
      title: 'React & Next.js App Router',
      subject: 'Modern Web Engineering',
      difficulty: 'Beginner',
      activeLearningContext: 'Server Components',
      progress: 0.35,
      flashcardsCount: 120,
      nodesCount: 14,
      color: const Color(0xFF10B981), // Emerald
      openedAgo: const Duration(days: 21),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 8. Data Structures & Algorithms
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_dsa_08',
      title: 'Data Structures & Algorithms',
      subject: 'Computer Science Core',
      difficulty: 'Advanced',
      activeLearningContext: 'Dynamic Programming',
      progress: 0.72,
      flashcardsCount: 410,
      nodesCount: 30,
      color: const Color(0xFFFFFFFF), // White
      openedAgo: const Duration(days: 60),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 9. DevOps & Kubernetes Infra
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_devops_09',
      title: 'DevOps & Kubernetes Infra',
      subject: 'Cloud & Orchestration',
      difficulty: 'Intermediate',
      activeLearningContext: 'Ingress Controllers',
      progress: 0.18,
      flashcardsCount: 140,
      nodesCount: 18,
      color: const Color(0xFFF59E0B), // Amber
      openedAgo: const Duration(days: 60),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));

    // 10. Prompt Engineering & LLMs
    _workspaces.add(_createSeedWorkspace(
      id: 'ws_llm_10',
      title: 'Prompt Engineering & LLMs',
      subject: 'Generative AI',
      difficulty: 'Beginner',
      activeLearningContext: 'Chain of Thought',
      progress: 0.10,
      flashcardsCount: 85,
      nodesCount: 12,
      color: const Color(0xFF67E8F9), // Cyan
      openedAgo: const Duration(days: 90),
      now: now,
      basePersona: basePersona,
      baseCluster: baseCluster,
      baseFlashcards: baseFlashcards,
      baseCells: baseCells,
      baseChat: baseChat,
    ));
  }

  WorkspaceModel _createSeedWorkspace({
    required String id,
    required String title,
    required String subject,
    required String difficulty,
    required String activeLearningContext,
    required double progress,
    required int flashcardsCount,
    required int nodesCount,
    required Color color,
    required Duration openedAgo,
    required DateTime now,
    required PersonaProfile basePersona,
    required SubjectCluster baseCluster,
    required List<FlashcardItem> baseFlashcards,
    required List<CanvasGridCell> baseCells,
    required List<ChatMessage> baseChat,
  }) {
    final track = DashboardTrack(
      id: 'track_$id',
      goal: 'Master High-Performance $title Architecture',
      status: 'ACCEPTED',
      nodes: [
        DashboardSkillNode(
          id: 'node_${id}_1',
          title: '$title Core Architecture & Foundations',
          description: 'Understanding memory models, core data structures, and allocation overhead.',
          status: NodeStatus.mastered,
          prerequisiteIds: [],
          category: 'Core Architecture',
          estimatedMinutes: 15,
        ),
        DashboardSkillNode(
          id: 'node_${id}_2',
          title: '$activeLearningContext & Deep Dive Mechanics',
          description: 'Advanced patterns and execution flow for $activeLearningContext.',
          status: NodeStatus.active,
          prerequisiteIds: ['node_${id}_1'],
          category: 'Deep Dive',
          estimatedMinutes: 25,
        ),
        DashboardSkillNode(
          id: 'node_${id}_3',
          title: 'Advanced Performance & Optimization in $title',
          description: 'Recycling frames, avoiding bottlenecks, and micro-optimizations.',
          status: NodeStatus.locked,
          prerequisiteIds: ['node_${id}_2'],
          category: 'Optimization',
          estimatedMinutes: 30,
        ),
      ],
    );

    final activityFeed = [
      ActivityEntry(
        id: 'act_${id}_1',
        type: ActivityType.nodeMastered,
        title: 'Node Mastered: $title Core Architecture',
        subtitle: 'Passed evaluation with score 100%',
        timestamp: now.subtract(openedAgo + const Duration(hours: 1)),
      ),
      ActivityEntry(
        id: 'act_${id}_2',
        type: ActivityType.cardReviewed,
        title: 'Spaced Repetition Practice Completed',
        subtitle: 'Reviewed 12 flashcards on $activeLearningContext',
        timestamp: now.subtract(openedAgo),
      ),
    ];

    return WorkspaceModel(
      id: id,
      userId: 'user_priyaj',
      title: title,
      subject: subject,
      difficulty: difficulty,
      createdAt: now.subtract(const Duration(days: 90)),
      lastOpened: now.subtract(openedAgo),
      progressPercent: progress,
      activeLearningContext: activeLearningContext,
      flashcardCount: flashcardsCount,
      roadmapNodeCount: nodesCount,
      accentColor: color,
      persona: _buildCustomPersona(id, title, subject, activeLearningContext, basePersona),
      subjectCluster: _buildCustomCluster(id, title, subject, activeLearningContext, baseCluster),
      roadmap: _buildCustomRoadmap(id, title, activeLearningContext),
      flashcards: _buildCustomFlashcards(id, title, activeLearningContext, baseFlashcards),
      canvasCells: _buildCustomCells(id, title, color, activeLearningContext, subject, baseCells),
      canvasObjects: [
        CanvasObject(id: 'note_${id}_1', label: '📌 $activeLearningContext\nKey Concepts', position: const Offset(660, 50), size: const Size(140, 80)),
        CanvasObject(id: 'note_${id}_2', label: '🔗 $title\nBest Practices', position: const Offset(660, 160), size: const Size(140, 80)),
      ],
      drawingPaths: [],
      chatHistory: _buildCustomChat(id, title, subject, activeLearningContext, baseChat),
      activityFeed: activityFeed,
      tracks: [track],
      activeTabId: 'roadmap',
    );
  }

  List<RoadmapNode> _buildCustomRoadmap(String id, String title, String activeContext) {
    if (title.contains('Python')) {
      return [
        RoadmapNode(
          id: 'rm_${id}_w1',
          title: 'Python Foundations',
          subtitle: 'Week 1',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w1_d1',
              title: 'Day 1',
              estimatedTime: '2h 15m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d1_a1', title: 'Python Installation', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a2', title: 'Variables', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a3', title: 'Data Types', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a4', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w1_d2',
              title: 'Day 2',
              estimatedTime: '1h 45m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d2_a1', title: 'Functions', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d2_a2', title: 'Arguments', estimatedTime: '25 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d2_a3', title: 'Coding Exercise', estimatedTime: '30 min', activityType: 'Coding Exercise', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w1_d3',
              title: 'Day 3',
              estimatedTime: '1h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d3_a1', title: 'Modules', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d3_a2', title: 'Packages', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d3_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w1_d4',
              title: 'Day 4',
              estimatedTime: '1h 20m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d4_a1', title: 'Error Handling', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d4_a2', title: 'Coding Exercise', estimatedTime: '30 min', activityType: 'Coding Exercise', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w2',
          title: 'Python OOP',
          subtitle: 'Week 2',
          progressPercent: 0.40,
          status: 'In Progress',
          isExpanded: true,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w2_d1',
              title: 'Day 1',
              estimatedTime: '1h 50m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d1_a1', title: 'Classes', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a2', title: 'Objects', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a3', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w2_d2',
              title: 'Day 2',
              estimatedTime: '2h 10m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d2_a1', title: 'Constructors', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d2_a2', title: 'Encapsulation', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d2_a3', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w2_d3',
              title: 'Day 3',
              estimatedTime: '1h 35m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d3_a1', title: 'Inheritance', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'In Progress', isSelected: true),
                RoadmapNode(id: 'rm_${id}_w2_d3_a2', title: 'Polymorphism', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w2_d3_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w2_d4',
              title: 'Day 4',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d4_a1', title: 'Abstraction', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w2_d4_a2', title: 'Magic Methods', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w2_d4_a3', title: 'Coding Exercise', estimatedTime: '30 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w3',
          title: 'Memory Management',
          subtitle: 'Week 3',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w3_d1',
              title: 'Day 1',
              estimatedTime: '1h 45m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d1_a1', title: 'Reference Counting', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a2', title: 'Garbage Collection', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w3_d2',
              title: 'Day 2',
              estimatedTime: '1h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d2_a1', title: 'Memory Pools & Arenas', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w3_d2_a2', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w4',
          title: 'Backend APIs',
          subtitle: 'Week 4',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w4_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w4_d1_a1', title: 'RESTful Principles', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a2', title: 'FastAPI Setup', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a3', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w4_d2',
              title: 'Day 2',
              estimatedTime: '1h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w4_d2_a1', title: 'Request Validation', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d2_a2', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w5',
          title: 'Authentication',
          subtitle: 'Week 5',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w5_d1',
              title: 'Day 1',
              estimatedTime: '1h 45m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w5_d1_a1', title: 'JWT & OAuth2', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a2', title: 'Security Headers', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w5_d2',
              title: 'Day 2',
              estimatedTime: '1h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w5_d2_a1', title: 'Permission Scopes', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d2_a2', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w6',
          title: 'Final Backend Project',
          subtitle: 'Week 6',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w6_d1',
              title: 'Day 1',
              estimatedTime: '4h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w6_d1_a1', title: 'Capstone Project', estimatedTime: '4h 00m', activityType: 'Capstone Project', status: 'Not Started'),
              ],
            ),
          ],
        ),
      ];
    } else if (title.contains('React')) {
      return [
        RoadmapNode(
          id: 'rm_${id}_w1',
          title: 'HTML & CSS Fundamentals',
          subtitle: 'Week 1',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w1_d1',
              title: 'Day 1',
              estimatedTime: '1h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d1_a1', title: 'HTML Structure', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a2', title: 'CSS Layouts', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w2',
          title: 'JavaScript & DOM',
          subtitle: 'Week 2',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w2_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d1_a1', title: 'JavaScript ES6+', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a2', title: 'DOM Manipulation', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a3', title: 'Coding Exercise', estimatedTime: '30 min', activityType: 'Coding Exercise', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w3',
          title: 'React Basics',
          subtitle: 'Week 3',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w3_d1',
              title: 'Day 1',
              estimatedTime: '2h 15m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d1_a1', title: 'React Basics', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a2', title: 'Components', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a3', title: 'Props', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w4',
          title: 'Hooks Architecture',
          subtitle: 'Week 4',
          progressPercent: 0.50,
          status: 'In Progress',
          isExpanded: true,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w4_d1',
              title: 'Day 1',
              estimatedTime: '1h 45m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w4_d1_a1', title: 'State Hooks', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a2', title: 'useState', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a3', title: 'useEffect', estimatedTime: '20 min', activityType: 'Learning Topic', status: 'Completed'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w4_d2',
              title: 'Day 2',
              estimatedTime: '1h 50m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w4_d2_a1', title: 'Context API', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'In Progress', isSelected: true),
                RoadmapNode(id: 'rm_${id}_w4_d2_a2', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d2_a3', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w5',
          title: 'React Router',
          subtitle: 'Week 5',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w5_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w5_d1_a1', title: 'React Router', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a2', title: 'Nested Routes', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a3', title: 'Coding Exercise', estimatedTime: '20 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w6',
          title: 'Redux',
          subtitle: 'Week 6',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w6_d1',
              title: 'Day 1',
              estimatedTime: '2h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w6_d1_a1', title: 'Redux Store', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w6_d1_a2', title: 'Reducers & Actions', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w6_d1_a3', title: 'Coding Exercise', estimatedTime: '30 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w7',
          title: 'Performance',
          subtitle: 'Week 7',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w7_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w7_d1_a1', title: 'Memoization', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w7_d1_a2', title: 'Code Splitting', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w7_d1_a3', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w8',
          title: 'Capstone React Project',
          subtitle: 'Week 8',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w8_d1',
              title: 'Day 1',
              estimatedTime: '5h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w8_d1_a1', title: 'Capstone React Project', estimatedTime: '5h 00m', activityType: 'Capstone Project', status: 'Not Started'),
              ],
            ),
          ],
        ),
      ];
    } else if (title.contains('Java')) {
      return [
        RoadmapNode(
          id: 'rm_${id}_w1',
          title: 'Collections Overview',
          subtitle: 'Week 1',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w1_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d1_a1', title: 'Collections Overview', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a2', title: 'ArrayList', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a3', title: 'LinkedList', estimatedTime: '25 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a4', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w2',
          title: 'Map Implementations',
          subtitle: 'Week 2',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w2_d1',
              title: 'Day 1',
              estimatedTime: '2h 15m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d1_a1', title: 'HashMap', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a2', title: 'TreeMap', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a3', title: 'HashSet', estimatedTime: '25 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a4', title: 'Coding Exercise', estimatedTime: '20 min', activityType: 'Coding Exercise', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w3',
          title: 'Queues & Deques',
          subtitle: 'Week 3',
          progressPercent: 0.40,
          status: 'In Progress',
          isExpanded: true,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w3_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d1_a1', title: 'Queue', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a2', title: 'Deque', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a3', title: 'Priority Queue', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'In Progress', isSelected: true),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w3_d2',
              title: 'Day 2',
              estimatedTime: '1h 00m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d2_a1', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w3_d2_a2', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w4',
          title: 'Sorting & Comparison',
          subtitle: 'Week 4',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w4_d1',
              title: 'Day 1',
              estimatedTime: '1h 45m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w4_d1_a1', title: 'Comparator', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a2', title: 'Comparable', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w4_d1_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w5',
          title: 'Streams API',
          subtitle: 'Week 5',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w5_d1',
              title: 'Day 1',
              estimatedTime: '2h 30m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w5_d1_a1', title: 'Streams', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a2', title: 'Lambda', estimatedTime: '50 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w5_d1_a3', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w6',
          title: 'Parallel Streams',
          subtitle: 'Week 6',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w6_d1',
              title: 'Day 1',
              estimatedTime: '1h 50m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w6_d1_a1', title: 'Parallel Streams', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w6_d1_a2', title: 'ForkJoinPool', estimatedTime: '30 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w6_d1_a3', title: 'Micro Quiz', estimatedTime: '20 min', activityType: 'Micro Quiz', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w7',
          title: 'Concurrent Collections',
          subtitle: 'Week 7',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w7_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w7_d1_a1', title: 'Concurrent Collections', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w7_d1_a2', title: 'CopyOnWriteArrayList', estimatedTime: '40 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w7_d1_a3', title: 'Coding Exercise', estimatedTime: '20 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w8',
          title: 'Interview Challenge',
          subtitle: 'Week 8',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w8_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w8_d1_a1', title: 'Interview Challenge', estimatedTime: '2h 00m', activityType: 'Interview Challenge', status: 'Not Started'),
              ],
            ),
          ],
        ),
      ];
    } else {
      return [
        RoadmapNode(
          id: 'rm_${id}_w1',
          title: '$title Foundations',
          subtitle: 'Week 1',
          progressPercent: 1.0,
          status: 'Completed',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w1_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w1_d1_a1', title: 'Core Concepts & Setup', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a2', title: 'Architecture Overview', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Completed'),
                RoadmapNode(id: 'rm_${id}_w1_d1_a3', title: 'Micro Quiz', estimatedTime: '15 min', activityType: 'Micro Quiz', status: 'Completed'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w2',
          title: '$activeContext & Deep Dive',
          subtitle: 'Week 2',
          progressPercent: 0.50,
          status: 'In Progress',
          isExpanded: true,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w2_d1',
              title: 'Day 1',
              estimatedTime: '2h 15m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d1_a1', title: activeContext, estimatedTime: '50 min', activityType: 'Learning Topic', status: 'In Progress', isSelected: true),
                RoadmapNode(id: 'rm_${id}_w2_d1_a2', title: 'Advanced Patterns', estimatedTime: '45 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w2_d1_a3', title: 'Coding Exercise', estimatedTime: '40 min', activityType: 'Coding Exercise', status: 'Not Started'),
              ],
            ),
            RoadmapNode(
              id: 'rm_${id}_w2_d2',
              title: 'Day 2',
              estimatedTime: '1h 30m',
              isExpanded: true,
              children: [
                RoadmapNode(id: 'rm_${id}_w2_d2_a1', title: 'Mini Project', estimatedTime: '1h 30m', activityType: 'Mini Project', status: 'Not Started'),
              ],
            ),
          ],
        ),
        RoadmapNode(
          id: 'rm_${id}_w3',
          title: 'Production Scaling & Mastery',
          subtitle: 'Week 3',
          progressPercent: 0.0,
          status: 'Not Started',
          isExpanded: false,
          children: [
            RoadmapNode(
              id: 'rm_${id}_w3_d1',
              title: 'Day 1',
              estimatedTime: '2h 00m',
              isExpanded: false,
              children: [
                RoadmapNode(id: 'rm_${id}_w3_d1_a1', title: 'High Concurrency & Scaling', estimatedTime: '60 min', activityType: 'Learning Topic', status: 'Not Started'),
                RoadmapNode(id: 'rm_${id}_w3_d1_a2', title: 'Mastery Assessment', estimatedTime: '60 min', activityType: 'Mastery Assessment', status: 'Not Started'),
              ],
            ),
          ],
        ),
      ];
    }
  }

  PersonaProfile _buildCustomPersona(String id, String title, String subject, String activeContext, PersonaProfile base) {
    if (id == 'ws_python_01') return base;
    return PersonaProfile(
      renderMode: 'Interactive Sandbox',
      title: title,
      subtitle: title.contains('React') ? 'Lead Frontend & Web Architect' : (title.contains('System Design') ? 'Principal Distributed Systems Architect' : 'Senior $title Specialist'),
      summary: 'Rigorous, pragmatic, and code-focused for $title.',
      traits: title.contains('React') ? ['React 19 Expert', 'Server Components', 'Hooks Architecture'] : (title.contains('System Design') ? ['Distributed Systems', 'Consensus Architect', 'Scalability'] : ['Systems Thinker', 'Fast Pacing', '$subject Master']),
      metrics: CognitiveMetrics(
        visualization: 0.85,
        applied: 0.90,
        theoretical: 0.75,
        pacing: 0.80,
        logic: 0.85,
      ),
      blueprintNodes: [
        BlueprintNode(id: 'b1', dayRange: 'Days 1 - 3', title: '$title Architecture Foundations', description: 'Core principles and data structures of $title.', topics: ['$title Basics', 'Core Architecture', 'Memory Model'], alternatives: ['Interactive Sandbox', 'Video Architecture Lecture', 'Text & Code Doc']),
        BlueprintNode(id: 'b2', dayRange: 'Days 4 - 7', title: '$activeContext Deep Dive', description: 'Advanced execution flow and memory patterns in $activeContext.', topics: [activeContext, 'Execution Flow', 'Design Patterns'], alternatives: ['Interactive Sandbox', 'Video Architecture Lecture', 'Text & Code Doc']),
        BlueprintNode(id: 'b3', dayRange: 'Days 8 - 14', title: 'Production Scaling in $title', description: 'High-concurrency bottlenecks and micro-optimizations.', topics: ['High Concurrency', 'Micro-optimizations', 'Production Scaling'], alternatives: ['Interactive Sandbox', 'Video Architecture Lecture', 'Text & Code Doc']),
      ],
    );
  }

  SubjectCluster _buildCustomCluster(String id, String title, String subject, String activeContext, SubjectCluster base) {
    if (id == 'ws_python_01') return base;

    List<ConceptNode> children = [];
    if (title.contains('React')) {
      children = [
        ConceptNode(id: 'node_${id}_c1', label: 'State Hooks & Lifecycle', isTerminal: true),
        ConceptNode(id: 'node_${id}_c2', label: 'Server Actions & Form Handling', isTerminal: false),
        ConceptNode(id: 'node_${id}_c3', label: 'Concurrent Rendering & Suspense', isTerminal: false),
        ConceptNode(id: 'node_${id}_c4', label: 'Custom Hook Design Patterns', isTerminal: false),
        ConceptNode(id: 'node_${id}_c5', label: 'Next.js App Router & SSR', isTerminal: false),
      ];
    } else if (title.contains('System Design')) {
      children = [
        ConceptNode(id: 'node_${id}_c1', label: 'Load Balancers & Reverse Proxies', isTerminal: true),
        ConceptNode(id: 'node_${id}_c2', label: 'CAP Theorem & Paxos Consensus', isTerminal: false),
        ConceptNode(id: 'node_${id}_c3', label: 'Distributed Caching & Redis', isTerminal: false),
        ConceptNode(id: 'node_${id}_c4', label: 'Database Sharding & Replication', isTerminal: false),
        ConceptNode(id: 'node_${id}_c5', label: 'Event-Driven Kafka Architecture', isTerminal: false),
      ];
    } else {
      children = [
        ConceptNode(id: 'node_${id}_c1', label: '$activeContext Foundations', isTerminal: true),
        ConceptNode(id: 'node_${id}_c2', label: 'Advanced $title Patterns', isTerminal: false),
        ConceptNode(id: 'node_${id}_c3', label: '$subject Mechanics', isTerminal: false),
        ConceptNode(id: 'node_${id}_c4', label: 'Performance & Scaling', isTerminal: false),
        ConceptNode(id: 'node_${id}_c5', label: 'Production Case Studies', isTerminal: false),
      ];
    }

    final root = ConceptNode(
      id: 'node_${id}_root',
      label: title,
      depthLevel: 0,
      isExpanded: true,
      children: children,
    );
    return SubjectCluster(
      subjectId: id,
      subjectTitle: title,
      rootNode: root,
    );
  }

  List<FlashcardItem> _buildCustomFlashcards(String id, String title, String activeContext, List<FlashcardItem> base) {
    if (id == 'ws_python_01') return List.from(base);

    if (title.contains('React')) {
      return [
        FlashcardItem(id: 'fc_${id}_1', topicTag: 'State Hooks', front: 'Why does React batch multiple useState updates inside event handlers?', back: 'Batching prevents redundant re-renders by deferring DOM updates until all event handler logic has executed.', easeFactor: 2.5, intervalDays: 3, consecutiveCorrect: 2, totalReviews: 2, nextReviewDate: DateTime.now().add(const Duration(days: 3))),
        FlashcardItem(id: 'fc_${id}_2', topicTag: 'State Hooks', front: 'What is the purpose of the cleanup function returned by useEffect?', back: 'It runs before the component unmounts and before subsequent re-runs of the effect, preventing memory leaks from timers or subscriptions.', easeFactor: 2.6, intervalDays: 5, consecutiveCorrect: 4, totalReviews: 4, nextReviewDate: DateTime.now().add(const Duration(days: 5))),
        FlashcardItem(id: 'fc_${id}_3', topicTag: 'Performance', front: 'When should you wrap a function with useCallback?', back: 'Only when passing callbacks as props to memoized child components (via React.memo) or when the callback is a dependency in useEffect/useMemo.', easeFactor: 2.4, intervalDays: 2, consecutiveCorrect: 1, totalReviews: 1, nextReviewDate: DateTime.now().add(const Duration(days: 2))),
        FlashcardItem(id: 'fc_${id}_4', topicTag: 'Custom Hooks', front: 'What makes a Custom Hook different from a standard helper utility function?', back: 'Custom Hooks can invoke standard React Hooks (useState, useEffect, useMemo) and couple reusable stateful logic across multiple components.', easeFactor: 2.5, intervalDays: 4, consecutiveCorrect: 3, totalReviews: 3, nextReviewDate: DateTime.now().add(const Duration(days: 4))),
      ];
    } else if (title.contains('System Design')) {
      return [
        FlashcardItem(id: 'fc_${id}_1', topicTag: 'Load Balancer', front: 'How does a Layer 7 load balancer differ from Layer 4?', back: 'Layer 7 inspects application-layer data (HTTP headers, cookies, URL paths) for routing, whereas Layer 4 routes purely based on TCP/UDP IP and port.', easeFactor: 2.5, intervalDays: 3, consecutiveCorrect: 2, totalReviews: 2, nextReviewDate: DateTime.now().add(const Duration(days: 3))),
        FlashcardItem(id: 'fc_${id}_2', topicTag: 'Consensus', front: 'In the CAP theorem, why can a distributed system not achieve both Consistency and Availability during a Partition?', back: 'When a network partition occurs, the system must either cancel the request to maintain consistency or respond with local stale data to maintain availability.', easeFactor: 2.6, intervalDays: 6, consecutiveCorrect: 5, totalReviews: 5, nextReviewDate: DateTime.now().add(const Duration(days: 6))),
        FlashcardItem(id: 'fc_${id}_3', topicTag: 'Scaling', front: 'What is Consistent Hashing and why is it critical for horizontal scaling?', back: 'Consistent hashing distributes keys across a ring of nodes so that adding or removing a node only re-maps K/N keys, preventing total cache invalidation.', easeFactor: 2.3, intervalDays: 1, consecutiveCorrect: 1, totalReviews: 1, nextReviewDate: DateTime.now().add(const Duration(days: 1))),
        FlashcardItem(id: 'fc_${id}_4', topicTag: 'Caching', front: 'What is the difference between Cache-Aside and Write-Through caching patterns?', back: 'In Cache-Aside, the application reads/writes directly to the database and populates the cache on misses; in Write-Through, writes go synchronously through the cache to the database.', easeFactor: 2.5, intervalDays: 4, consecutiveCorrect: 3, totalReviews: 3, nextReviewDate: DateTime.now().add(const Duration(days: 4))),
      ];
    } else {
      return [
        FlashcardItem(id: 'fc_${id}_1', topicTag: activeContext, front: 'What is the primary architectural principle of $title?', back: 'Structuring systems for modularity, low latency, and maintainable data flow.', easeFactor: 2.5, intervalDays: 3, consecutiveCorrect: 2, totalReviews: 2, nextReviewDate: DateTime.now().add(const Duration(days: 3))),
        FlashcardItem(id: 'fc_${id}_2', topicTag: activeContext, front: 'How do you optimize $activeContext in production environments?', back: 'By profiling execution paths, eliminating resource bottlenecks, and applying caching strategies.', easeFactor: 2.5, intervalDays: 4, consecutiveCorrect: 3, totalReviews: 3, nextReviewDate: DateTime.now().add(const Duration(days: 4))),
      ];
    }
  }

  List<CanvasGridCell> _buildCustomCells(String id, String title, Color color, String activeContext, String subject, List<CanvasGridCell> base) {
    if (id == 'ws_python_01') return List.from(base);

    if (title.contains('React')) {
      return [
        CanvasGridCell(id: 'cell_1', gridX: 0, gridY: 0, width: 280, height: 200, title: 'React Hooks Pipeline', diagramType: 'Concept Mindmap', nodeLabels: ['useState Fiber', 'useEffect Cleanup', 'Custom Hooks API']),
        CanvasGridCell(id: 'cell_2', gridX: 1, gridY: 0, width: 280, height: 220, title: 'Concurrent Rendering Model', diagramType: 'Flowchart Diagram', nodeLabels: ['Virtual DOM Tree', 'Fiber Reconciler', 'Commit Phase']),
      ];
    } else if (title.contains('System Design')) {
      return [
        CanvasGridCell(id: 'cell_1', gridX: 0, gridY: 0, width: 280, height: 200, title: 'Global Load Balancing Architecture', diagramType: 'Concept Mindmap', nodeLabels: ['DNS / Anycast', 'L4 NLB', 'L7 ALB / Ingress']),
        CanvasGridCell(id: 'cell_2', gridX: 1, gridY: 0, width: 280, height: 220, title: 'Consistent Hashing Ring', diagramType: 'Flowchart Diagram', nodeLabels: ['Virtual Nodes', 'Hash Ring (0-360)', 'Cache-Aside Replication']),
      ];
    } else {
      return [
        CanvasGridCell(id: 'cell_1', gridX: 0, gridY: 0, width: 280, height: 200, title: '$title Core Pipeline', diagramType: 'Concept Mindmap', nodeLabels: ['Client Layer', 'Gateway Service', '$activeContext Node']),
        CanvasGridCell(id: 'cell_2', gridX: 1, gridY: 0, width: 280, height: 220, title: '$activeContext Execution Model', diagramType: 'Flowchart Diagram', nodeLabels: ['State Allocation', 'Sync Rules', 'Error Handling']),
      ];
    }
  }

  List<ChatMessage> _buildCustomChat(String id, String title, String subject, String activeContext, List<ChatMessage> base) {
    if (id == 'ws_python_01') return List.from(base);

    final now = DateTime.now();
    if (title.contains('React')) {
      return [
        ChatMessage(id: 'msg_f1', sender: 'AI', text: 'Welcome to your **React Frontend Engineering** workspace! You are currently focusing on **State Hooks**. Shall we examine how batching and useEffect lifecycle cleanup work?', timestamp: now.subtract(const Duration(minutes: 15))),
        ChatMessage(id: 'msg_f2', sender: 'USER', text: 'Yes! How should I structure custom hooks when dealing with real-time WebSocket subscriptions in React 19?', timestamp: now.subtract(const Duration(minutes: 12))),
        ChatMessage(id: 'msg_f3', sender: 'AI', text: 'For WebSocket subscriptions, encapsulating the socket instance inside a custom hook with a `useEffect` cleanup return is essential. This ensures clean unmounting and prevents duplicate listeners in React 18+ strict mode.\n\nTake a look at the **React Hooks Pipeline** diagram in your Infinite Canvas tab for a visual breakdown.', timestamp: now.subtract(const Duration(minutes: 10))),
      ];
    } else if (title.contains('System Design')) {
      return [
        ChatMessage(id: 'msg_s1', sender: 'AI', text: 'Welcome back to **System Design**! Let\'s continue our deep dive into **Load Balancers**. Would you like to review health checks, SSL termination, or consistent hashing?', timestamp: now.subtract(const Duration(minutes: 25))),
        ChatMessage(id: 'msg_s2', sender: 'USER', text: 'Let\'s discuss where to handle SSL termination in a high-traffic microservices architecture.', timestamp: now.subtract(const Duration(minutes: 20))),
        ChatMessage(id: 'msg_s3', sender: 'AI', text: 'In high-traffic architectures, SSL termination is typically handled at the Layer 7 Load Balancer or Ingress Gateway (like NGINX or Envoy). This offloads CPU-intensive cryptographic handshakes from downstream microservices, allowing them to communicate over internal unencrypted HTTP/2 or gRPC.\n\nCheck out the **Global Load Balancing Architecture** cell on your Infinite Canvas!', timestamp: now.subtract(const Duration(minutes: 18))),
      ];
    } else {
      return [
        ChatMessage(id: 'msg_g1', sender: 'AI', text: 'Welcome to **$title**! Our current focus is **$activeContext**. What specific questions do you have about $subject architecture?', timestamp: now.subtract(const Duration(minutes: 30))),
        ChatMessage(id: 'msg_g2', sender: 'USER', text: 'Can you summarize the best practices for handling $activeContext?', timestamp: now.subtract(const Duration(minutes: 25))),
        ChatMessage(id: 'msg_g3', sender: 'AI', text: 'Absolutely! When working with **$activeContext** in **$title**, the top three best practices are:\n1. Maintain strict modularity across component boundaries.\n2. Monitor resource allocation to avoid contention.\n3. Implement automated fallback mechanisms for resilience.', timestamp: now.subtract(const Duration(minutes: 20))),
      ];
    }
  }

  @override
  Future<List<WorkspaceModel>> getAll() async {
    await _ensureInitialized();
    // Return sorted by lastOpened descending
    final list = List<WorkspaceModel>.from(_workspaces);
    list.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return list;
  }

  @override
  Future<WorkspaceModel?> getById(String id) async {
    await _ensureInitialized();
    try {
      return _workspaces.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WorkspaceModel> create(WorkspaceModel ws) async {
    await _ensureInitialized();
    _workspaces.removeWhere((w) => w.id == ws.id);
    _workspaces.insert(0, ws);
    return ws;
  }

  @override
  Future<void> update(WorkspaceModel ws) async {
    await _ensureInitialized();
    final index = _workspaces.indexWhere((w) => w.id == ws.id);
    if (index != -1) {
      _workspaces[index] = ws;
    }
  }

  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    _workspaces.removeWhere((w) => w.id == id);
  }

  @override
  Future<WorkspaceModel> duplicate(String id) async {
    await _ensureInitialized();
    final target = _workspaces.firstWhere((w) => w.id == id);
    final newId = '${id}_copy_${DateTime.now().millisecondsSinceEpoch}';
    final clone = target.clone(newId: newId, newTitle: '${target.title} (Copy)');
    _workspaces.insert(0, clone);
    return clone;
  }

  @override
  Future<void> archive(String id, {required bool isArchived}) async {
    await _ensureInitialized();
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workspaces[index].isArchived = isArchived;
    }
  }

  @override
  Future<void> pin(String id, {required bool isPinned}) async {
    await _ensureInitialized();
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workspaces[index].isPinned = isPinned;
    }
  }
}
