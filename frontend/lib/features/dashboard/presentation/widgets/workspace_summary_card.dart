import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class WorkspaceSummaryCard extends StatelessWidget {
  final WorkspaceSummaryData data;

  const WorkspaceSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: AppSpacing.pXl,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: colors.fgPrimary, size: 24),
              const SizedBox(width: 8),
              Text('Workspace Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(data.workspaceName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          const SizedBox(height: 24),

          _buildRow(context, 'Created', data.createdDate),
          const SizedBox(height: 16),
          _buildRow(context, 'Last Active', data.lastActive),
          const SizedBox(height: 16),
          _buildRow(context, 'Completion', '${(data.completionPercent * 100).round()}%'),
          const SizedBox(height: 16),
          _buildRow(context, 'Estimated Finish', '${data.estimatedFinishDays} Days'),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: colors.fgAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: const Text('Open Workspace →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: colors.fgSecondary)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.fgPrimary)),
      ],
    );
  }
}
