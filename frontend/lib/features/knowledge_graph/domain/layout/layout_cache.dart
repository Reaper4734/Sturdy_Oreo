import '../models/layout_result.dart';

/// Layout Cache avoiding full graph recalculations.
/// Stores exactly one immutable layout per workspace/graph ID.
class LayoutCache {
  final Map<String, LayoutResult> _cache = {};

  LayoutResult? get(String graphId) {
    return _cache[graphId];
  }

  void put(String graphId, LayoutResult result) {
    _cache[graphId] = result;
  }

  void invalidate(String graphId) {
    _cache.remove(graphId);
  }

  void clear() {
    _cache.clear();
  }
}
