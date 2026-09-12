import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';

class DividerBlockWidget extends StatelessWidget {
  const DividerBlockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: colors.borderSubtle,
        thickness: 1.2,
        height: 1.2,
      ),
    );
  }
}
