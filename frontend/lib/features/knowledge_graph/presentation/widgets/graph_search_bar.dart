import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/knowledge_graph_model.dart';

/// Floating auto-complete search bar that searches nodes in the Knowledge Graph.
/// Selecting a result automatically expands collapsed parents, centers viewport, and focuses the node.
class GraphSearchBar extends StatefulWidget {
  final KnowledgeGraph graph;
  final Function(GraphNode) onSelectNode;

  const GraphSearchBar({
    super.key,
    required this.graph,
    required this.onSelectNode,
  });

  @override
  State<GraphSearchBar> createState() => _GraphSearchBarState();
}

class _GraphSearchBarState extends State<GraphSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<GraphNode> _suggestions = [];
  bool _isOpen = false;

  void _onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isOpen = false;
      });
      return;
    }

    final lower = query.toLowerCase();
    final results = widget.graph.nodes.where((n) {
      return n.label.toLowerCase().contains(lower) ||
             n.description.toLowerCase().contains(lower);
    }).take(6).toList();

    setState(() {
      _suggestions = results;
      _isOpen = results.isNotEmpty;
    });
  }

  void _select(GraphNode node) {
    _controller.text = node.label;
    setState(() {
      _isOpen = false;
    });
    _focusNode.unfocus();
    widget.onSelectNode(node);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: colors.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: colors.fgSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  style: TextStyle(color: colors.fgPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: 'Search concepts, skills, tasks...',
                    hintStyle: TextStyle(color: colors.fgSecondary, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _onQueryChanged('');
                  },
                  child: Icon(Icons.close, color: colors.fgSecondary, size: 16),
                ),
            ],
          ),
        ),
        if (_isOpen) ...[
          const SizedBox(height: 4),
          Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: colors.borderSubtle, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(color: colors.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final node = _suggestions[index];
                return InkWell(
                  onTap: () => _select(node),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: TextStyle(
                            color: colors.fgPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (node.description.isNotEmpty)
                          Text(
                            node.description,
                            style: TextStyle(color: colors.fgSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
