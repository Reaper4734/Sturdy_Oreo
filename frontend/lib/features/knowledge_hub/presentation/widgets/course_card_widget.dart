import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/course_catalog_model.dart';

class CourseCardWidget extends StatefulWidget {
  final CourseCatalogEntry course;
  final VoidCallback onTap;

  const CourseCardWidget({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  State<CourseCardWidget> createState() => _CourseCardWidgetState();
}

class _CourseCardWidgetState extends State<CourseCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered ? colors.bgSurfaceHover : colors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? colors.borderDefault : colors.borderSubtle,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
                blurRadius: _isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.course.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.fgPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                widget.course.tags.join(' · '),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.fgSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: colors.fgAccent),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.course.estimatedHours} Hours',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.fgPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
