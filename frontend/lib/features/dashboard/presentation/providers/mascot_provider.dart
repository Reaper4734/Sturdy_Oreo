import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MascotState {
  final String companionAsset;
  final String mentorAsset;

  const MascotState({
    required this.companionAsset,
    required this.mentorAsset,
  });

  MascotState copyWith({
    String? companionAsset,
    String? mentorAsset,
  }) {
    return MascotState(
      companionAsset: companionAsset ?? this.companionAsset,
      mentorAsset: mentorAsset ?? this.mentorAsset,
    );
  }
}

class MascotNotifier extends StateNotifier<MascotState> {
  static const _companionKey = 'mascot_companion';
  static const _mentorKey = 'mascot_mentor';

  MascotNotifier()
      : super(const MascotState(
          companionAsset: 'animal-cat.png',
          mentorAsset: 'character-female-a.png',
        )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCompanion = prefs.getString(_companionKey);
    final savedMentor = prefs.getString(_mentorKey);

    if (savedCompanion != null || savedMentor != null) {
      state = state.copyWith(
        companionAsset: savedCompanion,
        mentorAsset: savedMentor,
      );
    }
  }

  Future<void> setCompanion(String asset) async {
    state = state.copyWith(companionAsset: asset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companionKey, asset);
  }

  Future<void> setMentor(String asset) async {
    state = state.copyWith(mentorAsset: asset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mentorKey, asset);
  }
}

final mascotProvider = StateNotifierProvider<MascotNotifier, MascotState>((ref) {
  return MascotNotifier();
});
