import 'dart:async';
import '../models/persona_model.dart';

class MockPersonaRepository {
  Future<PersonaProfile> getPersonaProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PersonaProfile(
      renderMode: 'VISUAL_CODE_ARCHITECT',
      title: 'Visual-First Code Architect',
      subtitle: 'High Practical Execution • Systems-Oriented Builder',
      summary:
          'You learn best by inspecting architectural flowcharts and working code snippets before diving into deep theory. Your profile favors rapid iteration with live feedback loops.',
      traits: [
        'Visual Learner',
        'Project-Driven',
        'Fast Pacing',
        'Systems Thinker',
      ],
      metrics: CognitiveMetrics(
        visualization: 0.88,
        applied: 0.92,
        theoretical: 0.65,
        pacing: 0.85,
        logic: 0.90,
      ),
      blueprintNodes: [
        BlueprintNode(
          id: 'b1',
          dayRange: 'Days 1 - 3',
          title: 'Python OOP & Memory Architecture',
          description: 'Master classes, inheritance, dunder methods, and memory pointers with interactive code visualizers.',
          topics: ['Dunder Methods', 'Inheritance Trees', 'Memory Management', 'Visual Flowcharts'],
          alternatives: ['Interactive Sandbox', 'Video Architecture Lecture', 'Text & Code Doc'],
          selectedFormat: 'Interactive Sandbox',
          isHandsOnFocus: true,
        ),
        BlueprintNode(
          id: 'b2',
          dayRange: 'Days 4 - 7',
          title: 'Asynchronous I/O & Concurrency Systems',
          description: 'Build async event loops, coroutines, and thread-safe queues with real-time benchmarks.',
          topics: ['Asyncio Loops', 'Coroutines', 'Thread Pools', 'Non-blocking I/O'],
          alternatives: ['Interactive Sandbox', 'Deep Theory Whitepaper'],
          selectedFormat: 'Interactive Sandbox',
          isHandsOnFocus: true,
        ),
        BlueprintNode(
          id: 'b3',
          dayRange: 'Days 8 - 11',
          title: 'Real-Time WebSocket Engine & STOMP',
          description: 'Implement bi-directional WebSocket streaming between Spring Boot Java backend and Flutter client.',
          topics: ['STOMP Protocol', 'Frame Decoders', 'Heartbeat Subscriptions', 'Reconnection Resiliency'],
          alternatives: ['Interactive Sandbox', 'Architectural Diagram Walkthrough'],
          selectedFormat: 'Interactive Sandbox',
          isHandsOnFocus: true,
        ),
        BlueprintNode(
          id: 'b4',
          dayRange: 'Days 12 - 14',
          title: 'Distributed System Capstone',
          description: 'Deploy full-stack interactive learning dashboard with automated AI code reviews.',
          topics: ['System Capstone', 'AI Review Integration', 'Production Docker Deployment'],
          alternatives: ['Full Capstone Repo', 'Guided Video Project'],
          selectedFormat: 'Full Capstone Repo',
          isHandsOnFocus: true,
        ),
      ],
    );
  }
}
