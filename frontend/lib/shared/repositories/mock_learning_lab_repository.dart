import 'dart:async';
import '../models/learning_lab_model.dart';

class MockLearningLabRepository {
  Future<List<TranscriptLine>> getTranscriptLines() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      TranscriptLine(id: 't1', timestampSeconds: 15, formattedTime: '00:15', text: 'Welcome to Python Heap Memory Architecture and Pointer Allocation.'),
      TranscriptLine(id: 't2', timestampSeconds: 90, formattedTime: '01:30', text: 'Every object in CPython is wrapped in a PyObject header containing ob_refcnt.'),
      TranscriptLine(id: 't3', timestampSeconds: 200, formattedTime: '03:20', text: 'When ref count drops to zero, garbage collector frees memory at 0x7FFF9A20.'),
      TranscriptLine(id: 't4', timestampSeconds: 342, formattedTime: '05:42', text: 'How memory allocation happens during dynamic dictionary hashing under high concurrency.'),
      TranscriptLine(id: 't5', timestampSeconds: 490, formattedTime: '08:10', text: 'Demonstrating circular reference detection using cyclic GC isolation algorithms.'),
      TranscriptLine(id: 't6', timestampSeconds: 615, formattedTime: '10:15', text: 'Building custom __new__ constructor overrides to intercept object instantiation.'),
    ];
  }

  Future<List<CanvasGridCell>> getInitialCanvasGrid() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      CanvasGridCell(
        id: 'cell_1',
        gridX: 0,
        gridY: 0,
        width: 280,
        height: 200,
        title: 'PyObject Memory Layout',
        diagramType: 'Concept Mindmap',
        nodeLabels: ['ob_refcnt (Ref Count)', 'ob_type (Type Pointer)', 'ob_digit (Value Payload)'],
      ),
      CanvasGridCell(
        id: 'cell_2',
        gridX: 1,
        gridY: 0,
        width: 280,
        height: 220,
        title: 'Garbage Collection Lifecycle',
        diagramType: 'Flowchart Diagram',
        nodeLabels: ['Generation 0 Scan', 'Generation 1 Promotion', 'Cycle Detector Sweep'],
      ),
    ];
  }
}
