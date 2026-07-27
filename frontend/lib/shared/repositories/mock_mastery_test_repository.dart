import '../models/mastery_test_model.dart';

class MockMasteryTestRepository {
  List<QuestionItem> getShortPopupQuestions() {
    return const [
      QuestionItem(
        id: 'q_short_1',
        topicTag: 'Heap Memory Header',
        questionText: 'What primary data header does CPython wrap around every allocated object instance?',
        type: QuestionType.shortPopup,
        options: [
          QuestionnaireOption(id: 'opt_1a', text: 'PyObject Header containing ob_refcnt & ob_type', isCorrect: true, explanation: 'Correct! All CPython heap instances are wrapped in PyObject.'),
          QuestionnaireOption(id: 'opt_1b', text: 'JVM Garbage Collector Header', isCorrect: false),
          QuestionnaireOption(id: 'opt_1c', text: 'V8 Hidden Class Structure', isCorrect: false),
          QuestionnaireOption(id: 'opt_1d', text: 'Raw Stack Frame Address', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_short_2',
        topicTag: 'Reference Counting',
        questionText: 'What exact action happens immediately when ob_refcnt drops to 0 in Python memory management?',
        type: QuestionType.shortPopup,
        options: [
          QuestionnaireOption(id: 'opt_2a', text: 'Memory at physical heap offset is deallocated instantly', isCorrect: true, explanation: 'Correct! Reference count 0 triggers immediate PyObject_Free.'),
          QuestionnaireOption(id: 'opt_2b', text: 'The object is saved to disk swap', isCorrect: false),
          QuestionnaireOption(id: 'opt_2c', text: 'The process crashes with SIGSEGV', isCorrect: false),
          QuestionnaireOption(id: 'opt_2d', text: 'Ref count increments automatically', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_short_3',
        topicTag: 'Pointer Allocation',
        questionText: 'Which memory arena allocator handles small memory blocks (<= 512 bytes) in CPython?',
        type: QuestionType.shortPopup,
        options: [
          QuestionnaireOption(id: 'opt_3a', text: 'PyMalloc Arena Allocator', isCorrect: true, explanation: 'Correct! PyMalloc manages small object pools in 256KB arenas.'),
          QuestionnaireOption(id: 'opt_3b', text: 'Standard System malloc()', isCorrect: false),
          QuestionnaireOption(id: 'opt_3c', text: 'Stack Pointer Register', isCorrect: false),
          QuestionnaireOption(id: 'opt_3d', text: 'Direct Kernel mmap', isCorrect: false),
        ],
      ),
    ];
  }

  List<QuestionItem> getLongMcqQuestions() {
    return const [
      QuestionItem(
        id: 'q_long_1',
        topicTag: 'PyObject Architecture',
        questionText: '1. In CPython, which two mandatory fields are defined inside the PyObject macro structure?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l1a', text: 'ob_refcnt (reference count) & ob_type (type object pointer)', isCorrect: true),
          QuestionnaireOption(id: 'l1b', text: 'vtable_ptr & thread_id', isCorrect: false),
          QuestionnaireOption(id: 'l1c', text: 'stack_offset & heap_limit', isCorrect: false),
          QuestionnaireOption(id: 'l1d', text: 'gc_phase & hash_code', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_2',
        topicTag: 'Cyclic Reference GC',
        questionText: '2. Why is traditional reference counting insufficient for reclaiming circular reference loops (A -> B -> A)?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l2a', text: 'Because both objects retain a non-zero ref count (>0) even when unreachable from root scope', isCorrect: true),
          QuestionnaireOption(id: 'l2b', text: 'Because Python does not support reference counting', isCorrect: false),
          QuestionnaireOption(id: 'l2c', text: 'Because memory pools are fixed at startup', isCorrect: false),
          QuestionnaireOption(id: 'l2d', text: 'Because stack variables cannot store pointers', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_3',
        topicTag: 'Generation GC',
        questionText: '3. How many generations does CPython cyclic garbage collector maintain for tracking long-lived objects?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l3a', text: '3 Generations (Gen 0, Gen 1, Gen 2)', isCorrect: true),
          QuestionnaireOption(id: 'l3b', text: '1 Single Global Pool', isCorrect: false),
          QuestionnaireOption(id: 'l3c', text: '5 Hierarchical Tiers', isCorrect: false),
          QuestionnaireOption(id: 'l3d', text: '16 Thread-Local Pools', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_4',
        topicTag: 'Small Object Pool',
        questionText: '4. What size threshold distinguishes PyMalloc small object allocation from system malloc?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l4a', text: 'Objects smaller than or equal to 512 bytes', isCorrect: true),
          QuestionnaireOption(id: 'l4b', text: 'Objects larger than 10 Megabytes', isCorrect: false),
          QuestionnaireOption(id: 'l4c', text: 'Objects under 4 Kilobytes', isCorrect: false),
          QuestionnaireOption(id: 'l4d', text: 'Only primitive integers', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_5',
        topicTag: 'GIL Impact',
        questionText: '5. How does the Global Interpreter Lock (GIL) interact with PyObject reference count increments?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l5a', text: 'It ensures atomic ref count updates across single-threaded execution passes', isCorrect: true),
          QuestionnaireOption(id: 'l5b', text: 'It disables reference counting completely', isCorrect: false),
          QuestionnaireOption(id: 'l5c', text: 'It forces synchronous disk flushes', isCorrect: false),
          QuestionnaireOption(id: 'l5d', text: 'It converts pointers into double values', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_6',
        topicTag: 'sys.getrefcount()',
        questionText: '6. When calling sys.getrefcount(obj), why is the returned reference count value 1 higher than expected?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l6a', text: 'Passing obj into getrefcount() creates a temporary argument reference on the function frame', isCorrect: true),
          QuestionnaireOption(id: 'l6b', text: 'Python adds a safety buffer of +1 to all counts', isCorrect: false),
          QuestionnaireOption(id: 'l6c', text: 'It counts global variables twice', isCorrect: false),
          QuestionnaireOption(id: 'l6d', text: 'It is a bug in the Python standard library', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_7',
        topicTag: 'Memory Defragmentation',
        questionText: '7. Does CPython automatically compact or defragment heap memory locations during garbage collection?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l7a', text: 'No, CPython does not move PyObject pointers in memory to prevent invalidating C-extension pointers', isCorrect: true),
          QuestionnaireOption(id: 'l7b', text: 'Yes, memory is compacted on every frame', isCorrect: false),
          QuestionnaireOption(id: 'l7c', text: 'Only on Windows operating systems', isCorrect: false),
          QuestionnaireOption(id: 'l7d', text: 'Only when running multithreaded code', isCorrect: false),
        ],
      ),
      QuestionItem(
        id: 'q_long_8',
        topicTag: 'Weak References',
        questionText: '8. How do weakref pointers allow inspecting target objects without altering memory lifecycle?',
        type: QuestionType.longMcq,
        options: [
          QuestionnaireOption(id: 'l8a', text: 'They reference PyObject without incrementing ob_refcnt', isCorrect: true),
          QuestionnaireOption(id: 'l8b', text: 'They double the ob_refcnt value', isCorrect: false),
          QuestionnaireOption(id: 'l8c', text: 'They force instant garbage collection', isCorrect: false),
          QuestionnaireOption(id: 'l8d', text: 'They prevent objects from ever being freed', isCorrect: false),
        ],
      ),
    ];
  }

  QuestionItem getCodeTerminalQuestion() {
    return const QuestionItem(
      id: 'q_code_1',
      topicTag: 'Interactive Code Terminal',
      questionText: 'Write a Python snippet using sys.getrefcount() to inspect object allocation and simulate reference count lifecycle.',
      type: QuestionType.codeTerminal,
      codeInitialTemplate: '''import sys

# Step 1: Instantiate PyObject target
target_data = {"concept": "CPython Heap", "size_bytes": 512}

# Step 2: Track reference count
ref_count = sys.getrefcount(target_data)
print(f"Initial ob_refcnt: {ref_count}")

# Step 3: Create secondary reference
alias_ref = target_data
new_count = sys.getrefcount(target_data)
print(f"After alias ob_refcnt: {new_count}")
''',
      codeSolution: '''import sys

# Step 1: Instantiate PyObject target
target_data = {"concept": "CPython Heap", "size_bytes": 512}

# Step 2: Track reference count
ref_count = sys.getrefcount(target_data)
print(f"Initial ob_refcnt: {ref_count}")

# Step 3: Create secondary reference
alias_ref = target_data
new_count = sys.getrefcount(target_data)
print(f"After alias ob_refcnt: {new_count}")
''',
      expectedOutput: '''Initial ob_refcnt: 2
After alias ob_refcnt: 3
[Test Suite] Pass: Reference count lifecycle verified!''',
      testCases: [
        CodeTestCase(
          id: 'tc_1',
          description: 'Verify sys.getrefcount initial count == 2',
          expectedOutput: 'Initial ob_refcnt: 2',
          userOutput: 'Initial ob_refcnt: 2',
          isPassed: true,
        ),
        CodeTestCase(
          id: 'tc_2',
          description: 'Verify alias reference increment == 3',
          expectedOutput: 'After alias ob_refcnt: 3',
          userOutput: 'After alias ob_refcnt: 3',
          isPassed: true,
        ),
      ],
    );
  }
}
