import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/theme_provider.dart';
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

  void _showSaveSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Row(
        children: [
          // Left Navigation Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              border: Border(right: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.fgPrimary,
                    ),
                  ),
                ),
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _activeSectionIndex == index;
                  return _buildNavItem(context, item, isActive, () {
                    setState(() => _activeSectionIndex = index);
                  });
                }),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildActiveSection(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, bool isActive, VoidCallback onTap) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.bgSurface : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? colors.accentPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive ? colors.fgPrimary : colors.fgSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? colors.fgPrimary : colors.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection(BuildContext context) {
    switch (_activeSectionIndex) {
      case 0:
        return _buildAccountSection(context);
      case 1:
        return _buildGeneralSection(context);
      case 2:
        return _buildNotificationsSection(context);
      case 3:
        return _buildDataPrivacySection(context);
      case 4:
        return _buildAboutSection(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Section 1: Account ───────────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 8),
        Text('Manage your profile information.', style: TextStyle(color: colors.fgSecondary)),
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
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: colors.fgSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: const Text('Change Photo'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderSubtle),
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
              Text(
                'EMAIL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_user.email, style: TextStyle(color: colors.fgPrimary, fontSize: 15)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.borderSubtle, width: 0.5),
                    ),
                    child: Text('Google', style: TextStyle(fontSize: 11, color: colors.fgSecondary)),
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

  Widget _buildGeneralSection(BuildContext context) {
    final colors = context.colors;
    final activeTheme = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 8),
        Text('Application preferences.', style: TextStyle(color: colors.fgSecondary)),
        const SizedBox(height: 32),

        Text('THEME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildRadioGroup(
          context: context,
          options: ['Dark', 'Light', 'System'],
          selected: activeTheme,
          onChanged: (v) {
            ref.read(themeModeProvider.notifier).setThemeMode(v);
            setState(() => _settings.themeMode = v);
            _showSaveSnackbar('Theme updated to $v');
          },
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 24),

        Text('LANGUAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildRadioGroup(
          context: context,
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
    required BuildContext context,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final colors = context.colors;
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
                      color: isSelected ? colors.accentPrimary : colors.fgSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.accentPrimary,
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
                    color: isSelected ? colors.fgPrimary : colors.fgSecondary,
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

  Widget _buildNotificationsSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 8),
        Text('Choose what notifications you receive.', style: TextStyle(color: colors.fgSecondary)),
        const SizedBox(height: 32),

        _buildSwitchRow(
          context: context,
          label: 'Course Updates',
          value: _notifications.courseUpdates,
          onChanged: (v) => setState(() => _notifications.courseUpdates = v),
        ),
        _buildSwitchRow(
          context: context,
          label: 'Community Announcements',
          value: _notifications.communityAnnouncements,
          onChanged: (v) => setState(() => _notifications.communityAnnouncements = v),
        ),
        _buildSwitchRow(
          context: context,
          label: 'Product Updates',
          value: _notifications.productUpdates,
          onChanged: (v) => setState(() => _notifications.productUpdates = v),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: colors.fgPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.accentEmerald,
            inactiveTrackColor: colors.bgElevated,
          ),
        ],
      ),
    );
  }

  // ─── Section 4: Data & Privacy ────────────────────────────────────────────

  Widget _buildDataPrivacySection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data & Privacy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 8),
        Text('Manage your personal learning data.', style: TextStyle(color: colors.fgSecondary)),
        const SizedBox(height: 32),

        Text('DATA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildActionRow(
                context: context,
                icon: Icons.download_outlined,
                title: 'Export Learning Data',
                description: 'Download your learning progress, completed topics and workspace data.',
                onTap: () {},
              ),
              Divider(color: colors.borderSubtle, height: 1),
              _buildActionRow(
                context: context,
                icon: Icons.note_alt_outlined,
                title: 'Download Notes',
                description: 'Export all personal notes created inside Oreo.',
                onTap: () {},
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        Text('PRIVACY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildPrivacyLinkRow(context, 'Privacy Policy', Icons.policy_outlined),
              Divider(color: colors.borderSubtle, height: 1),
              _buildPrivacyLinkRow(context, 'Terms of Service', Icons.description_outlined),
            ],
          ),
        ),

        const SizedBox(height: 48),
        Text('ACCOUNT ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.fgSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              _buildActionRow(
                context: context,
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
        Text('DANGER ZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentRose, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildDangerCard(
          context: context,
          title: 'Delete Workspace',
          description: 'Delete only the current workspace. Other workspaces remain unaffected.',
          buttonLabel: 'Delete',
          onTap: () => _showDeleteConfirmation(
            context: context,
            title: 'Delete this workspace?',
            content: 'Are you sure you want to delete this workspace?',
            confirmText: 'Delete',
          ),
        ),
        const SizedBox(height: 16),
        _buildDangerCard(
          context: context,
          title: 'Delete Account',
          description: 'Permanently remove your account and all associated data.\nThis action cannot be undone.',
          buttonLabel: 'Delete Account',
          onTap: () => _showDeleteConfirmation(
            context: context,
            title: 'Delete your account?',
            content: 'This action cannot be undone.',
            confirmText: 'Delete Account',
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.fgPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.fgPrimary)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right, size: 20, color: colors.fgSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyLinkRow(BuildContext context, String label, IconData icon) {
    final colors = context.colors;
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.fgPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.fgPrimary)),
            ),
            Icon(Icons.open_in_new, size: 16, color: colors.fgSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerCard({
    required BuildContext context,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.fgPrimary)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: colors.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accentRose,
              side: BorderSide(color: colors.accentRose.withValues(alpha: 0.5)),
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
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
  }) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.borderSubtle),
          ),
          title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
          content: Text(content, style: TextStyle(fontSize: 14, color: colors.fgSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: colors.fgSecondary),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: colors.accentRose),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ─── Section 5: About ─────────────────────────────────────────────────────

  Widget _buildAboutSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.fgPrimary)),
        const SizedBox(height: 8),
        Text('Application information.', style: TextStyle(color: colors.fgSecondary)),
        const SizedBox(height: 32),

        _buildInfoRow(context, 'Version', _about.appVersion),
        _buildInfoRow(context, 'Release Date', 'July 2026'),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),

        _buildLinkButton(context, 'Release Notes', Icons.new_releases_outlined),
        _buildLinkButton(context, 'Open Source Licenses', Icons.gavel_outlined),
        _buildLinkButton(context, 'GitHub Repository', Icons.code),
        _buildLinkButton(context, 'Contact Support', Icons.support_agent_outlined),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colors.fgSecondary)),
          Text(value, style: TextStyle(fontSize: 14, color: colors.fgPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String label, IconData icon) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.fgSecondary),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 15, color: colors.fgAccent)),
              const Spacer(),
              Icon(Icons.open_in_new, size: 14, color: colors.fgSecondary),
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
