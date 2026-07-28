import '../../domain/models/knowledge_graph_model.dart';

/// Provides realistic, high-density stress-test Knowledge Graph datasets
/// for all 3 Oreo workspaces as specified in the project requirements.
class MockKnowledgeGraphData {
  static final Map<String, KnowledgeGraph> _workspaces = {
    'python_backend': _buildPythonBackendGraph(),
    'react_frontend': _buildReactFrontendGraph(),
    'java_collections': _buildJavaCollectionsGraph(),
  };

  static KnowledgeGraph getWorkspaceGraph(String workspaceId) {
    final raw = _workspaces[workspaceId] ?? _workspaces['python_backend']!;
    final Map<String, List<String>> parentToChildren = {};
    for (final node in raw.nodes) {
      if (node.parentId != null) {
        parentToChildren.putIfAbsent(node.parentId!, () => []).add(node.id);
      }
    }
    final enrichedNodes = raw.nodes.map((node) {
      if (node.childrenNodeIds.isEmpty && parentToChildren.containsKey(node.id)) {
        return node.copyWith(childrenNodeIds: parentToChildren[node.id]!);
      }
      return node;
    }).toList();
    return raw.copyWith(nodes: enrichedNodes);
  }

  static List<String> getAvailableWorkspaceIds() => _workspaces.keys.toList();

  static String getWorkspaceTitle(String workspaceId) {
    return _workspaces[workspaceId]?.title ?? 'Knowledge Graph';
  }

  // ===========================================================================
  // WORKSPACE 1: PYTHON BACKEND ENGINEERING (Stress-Test Curriculum)
  // ===========================================================================
  static KnowledgeGraph _buildPythonBackendGraph() {
    final List<GraphNode> nodes = [
      // Section 1: OOP & Architecture
      const GraphNode(
        id: 'sec-oop',
        type: NodeType.section,
        label: 'OOP & Software Design',
        description: 'Object-Oriented Programming principles, metaclasses, and architectural patterns in Python.',
        status: NodeStatus.completed,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-classes',
        type: NodeType.topic,
        label: 'Classes & Inheritance',
        description: 'Deep dive into MRO (Method Resolution Order), super(), and abstract base classes.',
        status: NodeStatus.completed,
        parentId: 'sec-oop',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'sub-mro',
        type: NodeType.subtopic,
        label: 'C3 Linearization (MRO)',
        description: 'How Python resolves multiple inheritance diamond problems.',
        status: NodeStatus.completed,
        parentId: 'top-classes',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'sub-dataclasses',
        type: NodeType.subtopic,
        label: 'Dataclasses & Pydantic',
        description: 'Declarative data models, type validation, and serialization.',
        status: NodeStatus.completed,
        parentId: 'top-classes',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'quiz-oop-1',
        type: NodeType.quiz,
        label: 'Quiz: MRO & Metaclasses',
        description: 'Test your mastery of Python inheritance rules.',
        status: NodeStatus.completed,
        parentId: 'top-classes',
        metadata: NodeMetadata(activityType: 'MICRO_QUIZ', estimatedHours: 1),
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),

      // Section 2: Memory Management & CPython
      const GraphNode(
        id: 'sec-memory',
        type: NodeType.section,
        label: 'Memory & CPython Internals',
        description: 'Reference counting, cyclic garbage collection, and the GIL.',
        status: NodeStatus.inProgress,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-gil',
        type: NodeType.topic,
        label: 'Global Interpreter Lock (GIL)',
        description: 'Why CPython uses the GIL and how Python 3.13+ free-threading works.',
        status: NodeStatus.inProgress,
        parentId: 'sec-memory',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'sub-ref-count',
        type: NodeType.subtopic,
        label: 'Reference Counting',
        description: 'sys.getrefcount and immediate memory deallocation.',
        status: NodeStatus.completed,
        parentId: 'top-gil',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'sub-gc',
        type: NodeType.subtopic,
        label: 'Generational GC',
        description: 'Handling cyclic reference leaks in generation 0, 1, and 2 pools.',
        status: NodeStatus.inProgress,
        parentId: 'top-gil',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'opt-c-extensions',
        type: NodeType.optional,
        label: 'Optional: Cython & C-Extensions',
        description: 'Writing high-performance native C modules to bypass the GIL.',
        status: NodeStatus.notStarted,
        isOptional: true,
        parentId: 'top-gil',
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),

      // Section 3: Asynchronous Programming
      const GraphNode(
        id: 'sec-async',
        type: NodeType.section,
        label: 'Async & Concurrency',
        description: 'Event loops, coroutines, asyncio, and multiprocessing architectures.',
        status: NodeStatus.notStarted,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-asyncio',
        type: NodeType.topic,
        label: 'Asyncio Event Loop',
        description: 'Non-blocking I/O, async/await syntax, and TaskGroups.',
        status: NodeStatus.notStarted,
        parentId: 'sec-async',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'sub-coroutines',
        type: NodeType.subtopic,
        label: 'Coroutines & Futures',
        description: 'Under the hood of generators and yield from.',
        status: NodeStatus.notStarted,
        parentId: 'top-asyncio',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'proj-async-crawler',
        type: NodeType.project,
        label: 'Project: Async Web Scraper',
        description: 'Build a high-throughput 10,000 req/sec scraper using aiohttp.',
        status: NodeStatus.notStarted,
        parentId: 'top-asyncio',
        metadata: NodeMetadata(activityType: 'CODE_CHALLENGE', estimatedHours: 4),
        geometry: NodeGeometry(x: 0, y: 0, width: 260, height: 64),
      ),

      // Section 4: Databases & Persistence
      const GraphNode(
        id: 'sec-db',
        type: NodeType.section,
        label: 'Database Architectures',
        description: 'Relational vs NoSQL, connection pooling, and ORM performance.',
        status: NodeStatus.notStarted,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-orms',
        type: NodeType.topic,
        label: 'SQLAlchemy 2.0 & SQLModel',
        description: 'Async sessions, Unit of Work pattern, and query optimization.',
        status: NodeStatus.notStarted,
        parentId: 'sec-db',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'alt-postgres',
        type: NodeType.alternative,
        label: 'PostgreSQL (Recommended)',
        description: 'ACID transactions, JSONB indexing, and connection pooling with PgBouncer.',
        status: NodeStatus.notStarted,
        parentId: 'top-orms',
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
      const GraphNode(
        id: 'alt-redis',
        type: NodeType.alternative,
        label: 'Redis Caching & Pub/Sub',
        description: 'In-memory data structures, session storage, and rate limiting.',
        status: NodeStatus.notStarted,
        parentId: 'top-orms',
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
      const GraphNode(
        id: 'assess-backend-final',
        type: NodeType.assessment,
        label: 'Assessment: Backend Systems Architecture',
        description: 'Comprehensive evaluation of Python server scalability and design.',
        status: NodeStatus.notStarted,
        parentId: 'top-orms',
        metadata: NodeMetadata(activityType: 'LONG_QUIZ', estimatedHours: 3),
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
      const GraphNode(
        id: 'ref-pep8',
        type: NodeType.reference,
        label: 'Reference: PEP 8 & PEP 484',
        description: 'Official style guides and static type hinting specifications.',
        status: NodeStatus.notStarted,
        parentId: 'top-orms',
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
    ];

    final List<GraphEdge> edges = [
      const GraphEdge(id: 'e1', sourceNodeId: 'sec-oop', targetNodeId: 'top-classes', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e2', sourceNodeId: 'top-classes', targetNodeId: 'sub-mro', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e3', sourceNodeId: 'top-classes', targetNodeId: 'sub-dataclasses', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e4', sourceNodeId: 'top-classes', targetNodeId: 'quiz-oop-1', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e5', sourceNodeId: 'top-classes', targetNodeId: 'sec-memory', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e6', sourceNodeId: 'sec-memory', targetNodeId: 'top-gil', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e7', sourceNodeId: 'top-gil', targetNodeId: 'sub-ref-count', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e8', sourceNodeId: 'top-gil', targetNodeId: 'sub-gc', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e9', sourceNodeId: 'top-gil', targetNodeId: 'opt-c-extensions', routingType: EdgeRoutingType.orthogonalSmoothStep, style: EdgeStyle(isDashed: true, strokeColorHex: '#64748B')),
      const GraphEdge(id: 'e10', sourceNodeId: 'top-gil', targetNodeId: 'sec-async', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e11', sourceNodeId: 'sec-async', targetNodeId: 'top-asyncio', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e12', sourceNodeId: 'top-asyncio', targetNodeId: 'sub-coroutines', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e13', sourceNodeId: 'top-asyncio', targetNodeId: 'proj-async-crawler', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e14', sourceNodeId: 'top-asyncio', targetNodeId: 'sec-db', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e15', sourceNodeId: 'sec-db', targetNodeId: 'top-orms', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'e16', sourceNodeId: 'top-orms', targetNodeId: 'alt-postgres', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e17', sourceNodeId: 'top-orms', targetNodeId: 'alt-redis', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e18', sourceNodeId: 'top-orms', targetNodeId: 'assess-backend-final', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'e19', sourceNodeId: 'top-orms', targetNodeId: 'ref-pep8', routingType: EdgeRoutingType.orthogonalSmoothStep),
    ];

    return KnowledgeGraph(
      graphId: 'python_backend',
      title: 'Python Backend Engineering',
      description: 'Enterprise server-side architecture, concurrency, and performance optimization.',
      nodes: nodes,
      edges: edges,
    );
  }

  // ===========================================================================
  // WORKSPACE 2: REACT FRONTEND ENGINEERING
  // ===========================================================================
  static KnowledgeGraph _buildReactFrontendGraph() {
    final List<GraphNode> nodes = [
      const GraphNode(
        id: 'sec-react-core',
        type: NodeType.section,
        label: 'React 19 Core & Fiber Engine',
        description: 'Virtual DOM reconciliation, Concurrent Mode, and React Server Components (RSC).',
        status: NodeStatus.completed,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-hooks',
        type: NodeType.topic,
        label: 'Advanced Hooks & Actions',
        description: 'useTransition, useOptimistic, useActionState, and custom hook design.',
        status: NodeStatus.completed,
        parentId: 'sec-react-core',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'sub-closures',
        type: NodeType.subtopic,
        label: 'Stale Closures & Refs',
        description: 'Mastering dependency arrays and useRef memory lifecycle.',
        status: NodeStatus.completed,
        parentId: 'top-hooks',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'sec-state',
        type: NodeType.section,
        label: 'State Management Architectures',
        description: 'Global state, atomic stores, and server state caching.',
        status: NodeStatus.inProgress,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-zustand',
        type: NodeType.topic,
        label: 'Zustand & TanStack Query',
        description: 'Unidirectional data flow without Redux boilerplate.',
        status: NodeStatus.inProgress,
        parentId: 'sec-state',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'alt-redux',
        type: NodeType.alternative,
        label: 'Redux Toolkit (RTK)',
        description: 'Legacy enterprise state slices and middleware.',
        status: NodeStatus.notStarted,
        parentId: 'top-zustand',
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
      const GraphNode(
        id: 'proj-dashboard',
        type: NodeType.project,
        label: 'Project: Real-Time Analytics UI',
        description: 'Build a 60fps streaming WebSocket dashboard with optimistic UI updates.',
        status: NodeStatus.notStarted,
        parentId: 'top-zustand',
        metadata: NodeMetadata(activityType: 'CODE_CHALLENGE', estimatedHours: 5),
        geometry: NodeGeometry(x: 0, y: 0, width: 260, height: 64),
      ),
    ];

    final List<GraphEdge> edges = [
      const GraphEdge(id: 're1', sourceNodeId: 'sec-react-core', targetNodeId: 'top-hooks', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 're2', sourceNodeId: 'top-hooks', targetNodeId: 'sub-closures', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 're3', sourceNodeId: 'top-hooks', targetNodeId: 'sec-state', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 're4', sourceNodeId: 'sec-state', targetNodeId: 'top-zustand', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 're5', sourceNodeId: 'top-zustand', targetNodeId: 'alt-redux', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 're6', sourceNodeId: 'top-zustand', targetNodeId: 'proj-dashboard', routingType: EdgeRoutingType.orthogonalSmoothStep),
    ];

    return KnowledgeGraph(
      graphId: 'react_frontend',
      title: 'React Frontend Engineering',
      description: 'Modern web application architecture, state synchronization, and UI performance.',
      nodes: nodes,
      edges: edges,
    );
  }

  // ===========================================================================
  // WORKSPACE 3: JAVA COLLECTIONS & STREAMS
  // ===========================================================================
  static KnowledgeGraph _buildJavaCollectionsGraph() {
    final List<GraphNode> nodes = [
      const GraphNode(
        id: 'sec-collections',
        type: NodeType.section,
        label: 'Core Collections Hierarchy',
        description: 'java.util interfaces: Collection, List, Set, Queue, and Map.',
        status: NodeStatus.completed,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-lists',
        type: NodeType.topic,
        label: 'ArrayList vs LinkedList',
        description: 'Contiguous memory vs doubly linked nodes, Big-O complexity analysis.',
        status: NodeStatus.completed,
        parentId: 'sec-collections',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'sub-hashmap',
        type: NodeType.subtopic,
        label: 'HashMap & ConcurrentHashMap',
        description: 'Hash collisions, Red-Black tree binning, and lock stripping.',
        status: NodeStatus.completed,
        parentId: 'top-lists',
        geometry: NodeGeometry(x: 0, y: 0, width: 220, height: 46),
      ),
      const GraphNode(
        id: 'sec-streams',
        type: NodeType.section,
        label: 'Stream API & Functional Java',
        description: 'Lazy evaluation, intermediate vs terminal operations, and parallel streams.',
        status: NodeStatus.inProgress,
        geometry: NodeGeometry(x: 0, y: 0, width: 320, height: 56),
      ),
      const GraphNode(
        id: 'top-collectors',
        type: NodeType.topic,
        label: 'Advanced Collectors & Grouping',
        description: 'partitioningBy, groupingByConcurrent, and custom Collector implementations.',
        status: NodeStatus.inProgress,
        parentId: 'sec-streams',
        geometry: NodeGeometry(x: 0, y: 0, width: 280, height: 64),
      ),
      const GraphNode(
        id: 'quiz-java-streams',
        type: NodeType.quiz,
        label: 'Quiz: Streams & Lambdas',
        description: 'Test your understanding of Java 21 functional constructs.',
        status: NodeStatus.notStarted,
        parentId: 'top-collectors',
        metadata: NodeMetadata(activityType: 'MICRO_QUIZ', estimatedHours: 1),
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
      const GraphNode(
        id: 'assess-java-concurrency',
        type: NodeType.assessment,
        label: 'Assessment: High-Performance Java Collections',
        description: 'Evaluate thread-safe data structure design and memory visibility.',
        status: NodeStatus.notStarted,
        parentId: 'top-collectors',
        metadata: NodeMetadata(activityType: 'LONG_QUIZ', estimatedHours: 2),
        geometry: NodeGeometry(x: 0, y: 0, width: 200, height: 46),
      ),
    ];

    final List<GraphEdge> edges = [
      const GraphEdge(id: 'je1', sourceNodeId: 'sec-collections', targetNodeId: 'top-lists', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'je2', sourceNodeId: 'top-lists', targetNodeId: 'sub-hashmap', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'je3', sourceNodeId: 'top-lists', targetNodeId: 'sec-streams', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'je4', sourceNodeId: 'sec-streams', targetNodeId: 'top-collectors', routingType: EdgeRoutingType.cubicBezier),
      const GraphEdge(id: 'je5', sourceNodeId: 'top-collectors', targetNodeId: 'quiz-java-streams', routingType: EdgeRoutingType.orthogonalSmoothStep),
      const GraphEdge(id: 'je6', sourceNodeId: 'top-collectors', targetNodeId: 'assess-java-concurrency', routingType: EdgeRoutingType.orthogonalSmoothStep),
    ];

    return KnowledgeGraph(
      graphId: 'java_collections',
      title: 'Java Collections & Streams',
      description: 'Mastering Java data structures, time complexity, and functional stream pipelines.',
      nodes: nodes,
      edges: edges,
    );
  }
}
