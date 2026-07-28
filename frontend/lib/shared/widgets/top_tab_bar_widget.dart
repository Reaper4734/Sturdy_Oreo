import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class WorkspaceTabItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isClosable;

  WorkspaceTabItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isClosable = true,
  });
}

class TopTabBarWidget extends StatelessWidget {
  final List<WorkspaceTabItem> tabs;
  final String activeTabId;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<String>? onTabClosed;

  const TopTabBarWidget({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
    this.onTabClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.bgActivityBar,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab.id == activeTabId;
          return InkWell(
            onTap: () => onTabSelected(tab.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.bgCanvas : AppColors.bgActivityBar,
                border: Border(
                  right: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                  top: isActive ? const BorderSide(color: AppColors.accentPrimary, width: 2) : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(tab.icon, size: 14, color: isActive ? AppColors.accentPrimary : AppColors.fgSecondary),
                  const SizedBox(width: 8),
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.fgPrimary : AppColors.fgSecondary,
                    ),
                  ),
                  if (tab.isClosable && onTabClosed != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onTabClosed!(tab.id),
                      child: const Icon(Icons.close_rounded, size: 12, color: AppColors.fgSecondary),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
