import 'dart:async';
import '../models/mind_map_model.dart';

class MockMindMapRepository {
  Future<SubjectCluster> getSubjectCluster() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final root = ConceptNode(
      id: 'root_1',
      label: 'Python OOP & Memory Architecture',
      depthLevel: 0,
      isExpanded: true,
      children: [
        ConceptNode(
          id: 'n1',
          label: 'Dunder Methods',
          depthLevel: 1,
          isExpanded: true,
          children: [
            ConceptNode(id: 'n1_1', label: '__init__ & __new__', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n1_2', label: '__repr__ vs __str__', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n1_3', label: '__call__ Invocation', depthLevel: 2, isTerminal: true),
          ],
        ),
        ConceptNode(
          id: 'n2',
          label: 'Memory Pointers',
          depthLevel: 1,
          isExpanded: true,
          children: [
            ConceptNode(id: 'n2_1', label: 'Reference Counting', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n2_2', label: 'Garbage Collection', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n2_3', label: 'PyObject Struct Pointer', depthLevel: 2, isTerminal: true),
          ],
        ),
        ConceptNode(
          id: 'n3',
          label: 'Inheritance Trees',
          depthLevel: 1,
          isExpanded: false,
          children: [
            ConceptNode(id: 'n3_1', label: 'MRO (C3 Linearization)', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n3_2', label: 'Multiple Inheritance', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n3_3', label: 'Abstract Base Classes', depthLevel: 2, isTerminal: true),
          ],
        ),
        ConceptNode(
          id: 'n4',
          label: 'Async Event Loops',
          depthLevel: 1,
          isExpanded: false,
          children: [
            ConceptNode(id: 'n4_1', label: 'Coroutines & Futures', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n4_2', label: 'Task Scheduling', depthLevel: 2, isTerminal: true),
          ],
        ),
        ConceptNode(
          id: 'n5',
          label: 'Concurrency Systems',
          depthLevel: 1,
          isExpanded: false,
          children: [
            ConceptNode(id: 'n5_1', label: 'Thread Pools vs GIL', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n5_2', label: 'Multiprocessing Queues', depthLevel: 2, isTerminal: true),
          ],
        ),
        ConceptNode(
          id: 'n6',
          label: 'WebSocket Protocol',
          depthLevel: 1,
          isExpanded: false,
          children: [
            ConceptNode(id: 'n6_1', label: 'STOMP Framing', depthLevel: 2, isTerminal: true),
            ConceptNode(id: 'n6_2', label: 'Heartbeat Resiliency', depthLevel: 2, isTerminal: true),
          ],
        ),
      ],
    );

    return SubjectCluster(
      subjectId: 's1',
      subjectTitle: 'Python OOP & Memory Architecture',
      rootNode: root,
    );
  }
}
