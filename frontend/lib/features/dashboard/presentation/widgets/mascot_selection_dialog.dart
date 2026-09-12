import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/mascot_provider.dart';

enum MascotType { companion, mentor }

class MascotSelectionDialog extends ConsumerWidget {
  final MascotType type;

  const MascotSelectionDialog({super.key, required this.type});

  static const _petAssets = [
    'animal-beaver.png', 'animal-bee.png', 'animal-bunny.png', 'animal-cat.png',
    'animal-caterpillar.png', 'animal-chick.png', 'animal-cow.png', 'animal-crab.png',
    'animal-deer.png', 'animal-dog.png', 'animal-elephant.png', 'animal-fish.png',
    'animal-fox.png', 'animal-giraffe.png', 'animal-hog.png', 'animal-koala.png',
    'animal-lion.png', 'animal-monkey.png', 'animal-panda.png', 'animal-parrot.png',
    'animal-penguin.png', 'animal-pig.png', 'animal-polar.png', 'animal-tiger.png',
  ];

  static const _characterAssets = [
    'character-female-a.png', 'character-female-b.png', 'character-female-c.png',
    'character-female-d.png', 'character-female-e.png', 'character-female-f.png',
    'character-male-a.png', 'character-male-b.png', 'character-male-c.png',
    'character-male-d.png', 'character-male-e.png', 'character-male-f.png',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final assets = type == MascotType.companion ? _petAssets : _characterAssets;
    final basePath = type == MascotType.companion
        ? 'assets/mascots/cube_pets/png/'
        : 'assets/mascots/cube_characters/png/';
    final title = type == MascotType.companion ? 'Choose Companion' : 'Choose Mentor';
    
    final currentState = ref.watch(mascotProvider);
    final currentSelection = type == MascotType.companion
        ? currentState.companionAsset
        : currentState.mentorAsset;

    return Dialog(
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.fgPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.fgSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: assets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  final isSelected = asset == currentSelection;
                  
                  return InkWell(
                    onTap: () {
                      if (type == MascotType.companion) {
                        ref.read(mascotProvider.notifier).setCompanion(asset);
                      } else {
                        ref.read(mascotProvider.notifier).setMentor(asset);
                      }
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
                        border: Border.all(
                          color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset('$basePath$asset', fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
