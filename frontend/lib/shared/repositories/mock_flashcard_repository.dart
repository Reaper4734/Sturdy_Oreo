import 'dart:async';
import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

class MockFlashcardRepository {
  static final List<FlashcardItem> _cards = [
    // --- Topic: Heap Memory (Current Topic in Lab) ---
    FlashcardItem(
      id: 'fc_1',
      front: 'What does ob_refcnt represent in CPython\'s PyObject header?',
      back: 'It tracks the total number of references pointing to an object instance. When ob_refcnt drops to 0, memory is immediately freed.',
      topicTag: 'Heap Memory',
      type: FlashcardType.basic,
      tags: ['concept', 'definition'],
      easeFactor: 2.7,
      intervalDays: 3,
      consecutiveCorrect: 2,
      position: const Offset(40, 40),
    ),
    FlashcardItem(
      id: 'fc_2',
      front: 'In CPython, memory allocation for small objects (<= 512 bytes) is handled by ____ rather than system malloc.',
      back: 'PyMalloc (arena & pool allocator)',
      topicTag: 'Heap Memory',
      type: FlashcardType.fillBlank,
      tags: ['definition', 'code'],
      easeFactor: 2.1,
      intervalDays: 1,
      consecutiveCorrect: 1,
      position: const Offset(360, 40),
    ),
    FlashcardItem(
      id: 'fc_3',
      front: 'cpython_allocator.c snippet:\nvoid* ptr = PyObject_Malloc(size);\nif (!ptr) return NULL;\n\nWhat happens if size > 512 bytes?',
      back: 'PyObject_Malloc redirects the allocation to raw system malloc() bypassing PyMalloc pools.',
      topicTag: 'Heap Memory',
      type: FlashcardType.codeSnippet,
      tags: ['code', 'example'],
      easeFactor: 1.8,
      intervalDays: 1,
      consecutiveCorrect: 0,
      position: const Offset(680, 40),
    ),
    FlashcardItem(
      id: 'fc_4',
      front: 'What is the purpose of ob_type in PyObject?',
      back: 'A pointer to the type object (PyTypeObject) defining method suites, attributes, and memory layout for that instance.',
      topicTag: 'Heap Memory',
      type: FlashcardType.basic,
      tags: ['concept'],
      easeFactor: 2.9,
      intervalDays: 6,
      consecutiveCorrect: 3,
      position: const Offset(1000, 40),
    ),

    // --- Topic: GC Lifecycle (Other Session Cards) ---
    FlashcardItem(
      id: 'fc_5',
      front: 'Why does Python need a cyclic garbage collector in addition to reference counting?',
      back: 'Reference counting fails to free circular references (e.g. object A points to B and B points to A). Cyclic GC detects and sweeps isolated cycles.',
      topicTag: 'GC Lifecycle',
      type: FlashcardType.basic,
      tags: ['concept', 'definition'],
      easeFactor: 2.6,
      intervalDays: 4,
      consecutiveCorrect: 2,
      position: const Offset(40, 300),
    ),
    FlashcardItem(
      id: 'fc_6',
      front: 'CPython GC divides container objects into ____ generations (Gen 0, Gen 1, Gen 2).',
      back: 'Three generations',
      topicTag: 'GC Lifecycle',
      type: FlashcardType.fillBlank,
      tags: ['definition'],
      easeFactor: 3.1,
      intervalDays: 10,
      consecutiveCorrect: 4,
      position: const Offset(360, 300),
    ),
    FlashcardItem(
      id: 'fc_7',
      front: 'gc_sweep.py:\nimport gc\ngc.collect(2)\n\nWhat does gc.collect(2) perform?',
      back: 'Triggers a full garbage collection cycle examining Generation 0, 1, and 2 container objects.',
      topicTag: 'GC Lifecycle',
      type: FlashcardType.codeSnippet,
      tags: ['code', 'example'],
      easeFactor: 2.4,
      intervalDays: 2,
      consecutiveCorrect: 1,
      position: const Offset(680, 300),
    ),
    FlashcardItem(
      id: 'fc_8',
      front: 'What happens to objects surviving a Generation 0 GC pass?',
      back: 'They are promoted to Generation 1. If they survive Gen 1 passes, they move to Generation 2.',
      topicTag: 'GC Lifecycle',
      type: FlashcardType.basic,
      tags: ['concept'],
      easeFactor: 2.8,
      intervalDays: 5,
      consecutiveCorrect: 2,
      position: const Offset(1000, 300),
    ),
  ];

  Future<List<FlashcardItem>> getFlashcardsForTopic(String topicTag) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cards.where((c) => c.topicTag.toLowerCase() == topicTag.toLowerCase()).toList();
  }

  Future<List<FlashcardItem>> getAllFlashcards() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_cards);
  }

  // SM-2 Review Simulation
  FlashcardItem reviewCard(String id, int quality) {
    final card = _cards.firstWhere((c) => c.id == id);
    card.totalReviews += 1;

    if (quality < 3) {
      card.consecutiveCorrect = 0;
      card.intervalDays = 1;
    } else {
      card.consecutiveCorrect += 1;
      if (card.consecutiveCorrect == 1) {
        card.intervalDays = 1;
      } else if (card.consecutiveCorrect == 2) {
        card.intervalDays = 3;
      } else {
        card.intervalDays = (card.intervalDays * card.easeFactor).round();
      }
    }

    double newEase = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEase < 1.3) newEase = 1.3;
    card.easeFactor = newEase;
    card.nextReviewDate = DateTime.now().add(Duration(days: card.intervalDays));

    return card;
  }
}
