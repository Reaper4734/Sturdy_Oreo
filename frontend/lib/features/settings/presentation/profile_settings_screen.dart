import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../data/settings_model.dart';
import '../data/http_settings_repository.dart';
import 'widgets/inline_edit_field.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  int _activeSectionIndex = 0;
  late UserProfile _user;
  late AppThemeSettings _settings;
  late NotificationPreferences _notifications;
  final AboutInformation _about = AboutInformation.data;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.person_outline, label: 'Account'),
    _NavItem(icon: Icons.tune, label: 'General'),
    _NavItem(icon: Icons.notifications_none, label: 'Notifications'),
    _NavItem(icon: Icons.shield_outlined, label: 'Data & Privacy'),
    _NavItem(icon: Icons.info_outline, label: 'About'),
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final repo = ref.read(httpSettingsRepositoryProvider);
      final data = await repo.fetchSettingsProfile();
      if (mounted) {
        setState(() {
          _user = data['user'];
          _settings = data['settings'];
          _notifications = data['notifications'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSaveSnackbar(String message) {}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Row(
        children: [
          // Left Navigation Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.bgActivityBar,
              border: Border(right: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fgPrimary,
                    ),
                  ),
                ),
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _activeSectionIndex == index;
                  return _buildNavItem(item, isActive, () {
                    setState(() => _activeSectionIndex = index);
                  });
                }),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildActiveSection(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.bgSurface : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.accentPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive ? AppColors.fgPrimary : AppColors.fgSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.fgPrimary : AppColors.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeSectionIndex) {
      case 0:
        return _buildAccountSection();
      case 1:
        return _buildGeneralSection();
      case 2:
        return _buildNotificationsSection();
      case 3:
        return _buildDataPrivacySection();
      case 4:
        return _buildAboutSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Section 1: Account ───────────────────────────────────────────────────

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 8),
        const Text('Manage your profile information.', style: TextStyle(color: AppColors.fgSecondary)),
        const SizedBox(height: 32),

        // Avatar
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFD97706),
              child: Text(
                _user.avatarInitials,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            TextButton(
              onPressed: () {
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.fgSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: const Text('Change Photo'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: AppColors.borderSubtle),
        const SizedBox(height: 24),

        InlineEditField(
          label: 'DISPLAY NAME',
          value: _user.displayName,
          onSave: (v) {
            setState(() => _user.displayName = v);
            _showSaveSnackbar('Profile Updated Successfully');
          },
        ),
        // Email — not editable
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMAIL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_user.email, style: const TextStyle(color: AppColors.fgPrimary, fontSize: 15)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Google', style: TextStyle(fontSize: 11, color: AppColors.fgSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
        InlineEditField(
          label: 'BIO',
          value: _user.bio,
          onSave: (v) {
            setState(() => _user.bio = v);
            _showSaveSnackbar('Profile Updated Successfully');
          },
        ),
        InlineEditField(
          label: 'COUNTRY',
          value: _user.country,
          onSave: (v) {
            setState(() => _user.country = v);
            _showSaveSnackbar('Profile Updated Successfully');
          },
        ),
      ],
    );
  }

  // ─── Section 2: General ───────────────────────────────────────────────────

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('General', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 8),
        const Text('Application preferences.', style: TextStyle(color: AppColors.fgSecondary)),
        const SizedBox(height: 32),

        const Text('THEME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildRadioGroup(
          options: ['Dark', 'Light', 'System'],
          selected: _settings.themeMode,
          onChanged: (v) {
            setState(() => _settings.themeMode = v);
            _showSaveSnackbar('Theme updated to $v');
          },
        ),
        const SizedBox(height: 32),
        const Divider(color: AppColors.borderSubtle),
        const SizedBox(height: 24),

        const Text('LANGUAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildRadioGroup(
          options: ['English', 'Auto Detect'],
          selected: _settings.language,
          onChanged: (v) {
            setState(() => _settings.language = v);
            _showSaveSnackbar('Language updated to $v');
          },
        ),
      ],
    );
  }

  Widget _buildRadioGroup({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return InkWell(
          onTap: () => onChanged(opt),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accentPrimary : AppColors.fgSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  opt,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? AppColors.fgPrimary : AppColors.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Section 3: Notifications ─────────────────────────────────────────────

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 8),
        const Text('Choose what notifications you receive.', style: TextStyle(color: AppColors.fgSecondary)),
        const SizedBox(height: 32),

        _buildSwitchRow(
          label: 'Course Updates',
          value: _notifications.courseUpdates,
          onChanged: (v) => setState(() => _notifications.courseUpdates = v),
        ),
        _buildSwitchRow(
          label: 'Community Announcements',
          value: _notifications.communityAnnouncements,
          onChanged: (v) => setState(() => _notifications.communityAnnouncements = v),
        ),
        _buildSwitchRow(
          label: 'Product Updates',
          value: _notifications.productUpdates,
          onChanged: (v) => setState(() => _notifications.productUpdates = v),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.fgPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentEmerald,
            inactiveTrackColor: AppColors.bgElevated,
          ),
        ],
      ),
    );
  }

  // ─── Section 4: Data & Privacy ────────────────────────────────────────────

  Widget _buildDataPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data & Privacy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 8),
        const Text('Manage your personal learning data.', style: TextStyle(color: AppColors.fgSecondary)),
        const SizedBox(height: 32),

        const Text('DATA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildActionRow(
                icon: Icons.download_outlined,
                title: 'Export Learning Data',
                description: 'Download your learning progress, completed topics and workspace data.',
                onTap: () {},
              ),
              const Divider(color: AppColors.borderSubtle, height: 1),
              _buildActionRow(
                icon: Icons.note_alt_outlined,
                title: 'Download Notes',
                description: 'Export all personal notes created inside Oreo.',
                onTap: () {},
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        const Text('PRIVACY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildPrivacyLinkRow('Privacy Policy', Icons.policy_outlined),
              const Divider(color: AppColors.borderSubtle, height: 1),
              _buildPrivacyLinkRow('Terms of Service', Icons.description_outlined),
            ],
          ),
        ),

        const SizedBox(height: 48),
        const Text('ACCOUNT ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildActionRow(
                icon: Icons.logout_outlined,
                title: 'Log Out',
                description: 'Sign out of your current session securely.',
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        const Text('DANGER ZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentRose, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildDangerCard(
          title: 'Delete Workspace',
          description: 'Delete only the current workspace. Other workspaces remain unaffected.',
          buttonLabel: 'Delete',
          onTap: () => _showDeleteConfirmation(
            title: 'Delete this workspace?',
            content: 'Are you sure you want to delete this workspace?',
            confirmText: 'Delete',
          ),
        ),
        const SizedBox(height: 16),
        _buildDangerCard(
          title: 'Delete Account',
          description: 'Permanently remove your account and all associated data.\nThis action cannot be undone.',
          buttonLabel: 'Delete Account',
          onTap: () => _showDeleteConfirmation(
            title: 'Delete your account?',
            content: 'This action cannot be undone.',
            confirmText: 'Delete Account',
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.fgPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.fgPrimary)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.fgSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyLinkRow(String label, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.fgPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.fgPrimary)),
            ),
            const Icon(Icons.open_in_new, size: 16, color: AppColors.fgSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerCard({
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.fgPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: AppColors.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentRose,
              side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required String content,
    required String confirmText,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
          content: Text(content, style: const TextStyle(fontSize: 14, color: AppColors.fgSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.fgSecondary),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.accentRose),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ─── Section 5: About ─────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fgPrimary)),
        const SizedBox(height: 8),
        const Text('Application information.', style: TextStyle(color: AppColors.fgSecondary)),
        const SizedBox(height: 32),

        _buildInfoRow('Version', _about.appVersion),
        _buildInfoRow('Release Date', 'July 2026'),
        const SizedBox(height: 16),
        const Divider(color: AppColors.borderSubtle),
        const SizedBox(height: 16),

        _buildLinkButton('Release Notes', Icons.new_releases_outlined),
        _buildLinkButton('Open Source Licenses', Icons.gavel_outlined),
        _buildLinkButton('GitHub Repository', Icons.code),
        _buildLinkButton('Contact Support', Icons.support_agent_outlined),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.fgSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.fgPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.fgSecondary),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 15, color: AppColors.fgAccent)),
              const Spacer(),
              const Icon(Icons.open_in_new, size: 14, color: AppColors.fgSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
