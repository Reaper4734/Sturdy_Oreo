import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_model.dart';

class WorkspaceSummaryCard extends StatelessWidget {
  final WorkspaceSummaryData data;

  const WorkspaceSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: AppColors.fgPrimary, size: 24),
              SizedBox(width: 8),
              Text('Workspace Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(data.workspaceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          const SizedBox(height: 24),

          _buildRow('Created', data.createdDate),
          const SizedBox(height: 16),
          _buildRow('Last Active', data.lastActive),
          const SizedBox(height: 16),
          _buildRow('Completion', '${(data.completionPercent * 100).round()}%'),
          const SizedBox(height: 16),
          _buildRow('Estimated Finish', '${data.estimatedFinishDays} Days'),
          
          const SizedBox(height: 32),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.fgAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: const Text('Open Workspace →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.fgSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.fgPrimary)),
      ],
    );
  }
}
