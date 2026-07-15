import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---- controllers ----
  final _nameController = TextEditingController(text: 'Flavio Bellomo');
  final _emailController = TextEditingController(text: 'flavio@gmail.com');

  // ---- notification toggles ----
  bool _emailAlerts = true;
  bool _weeklySummary = true;
  bool _pilotAnomalies = false;

  // ---- edit mode ----
  bool _isEditingProfile = false;
  bool _isSaving = false;

  // ---- colori (stessa palette) ----
  static const _bgColor = Color(0xFFF2F4F7);
  static const _cardColor = Colors.white;
  static const _accentColor = Color(0xFF3B6FD4);
  static const _textPrimary = Color(0xFF1A1D23);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ---- save profile handler (pronto per auth/backend) ----
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      // TODO: await UserService.updateProfile(
      //   name: _nameController.text.trim(),
      //   email: _emailController.text.trim(),
      // );
      await Future.delayed(const Duration(milliseconds: 800)); // placeholder
      if (mounted) {
        setState(() => _isEditingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---- toggle notification handler (pronto per backend) ----
  Future<void> _updateNotification(String key, bool value) async {
    // TODO: await NotificationService.update(key: key, value: value);
    debugPrint('Notification [$key] set to $value');
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildRoleCard(),
                  const SizedBox(height: 16),
                  _buildNotificationsCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- page header ----
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your account and preferences',
          style: TextStyle(fontSize: 14, color: _textSecondary),
        ),
      ],
    );
  }

  // ---- card wrapper ----
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildCardTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  // ---- PROFILE CARD ----
  Widget _buildProfileCard() {
    final initials = _nameController.text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardTitle('Profile'),
              _isEditingProfile
                  ? Row(
                      children: [
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _isEditingProfile = false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    )
                  : TextButton.icon(
                      onPressed: () => setState(() => _isEditingProfile = true),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: _accentColor,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          color: _accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 20),

          // avatar + name/email row
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _accentColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _emailController.text,
                    style: const TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: _borderColor, thickness: 1),
          const SizedBox(height: 20),

          // fields
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 480;
              final nameField = _buildProfileField(
                label: 'Full Name',
                controller: _nameController,
                enabled: _isEditingProfile,
                icon: Icons.person_outline_rounded,
              );
              final emailField = _buildProfileField(
                label: 'Email',
                controller: _emailController,
                enabled: _isEditingProfile,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 16),
                    Expanded(child: emailField),
                  ],
                );
              }
              return Column(
                children: [nameField, const SizedBox(height: 16), emailField],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 17, color: _textSecondary),
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF8F9FB)
                : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accentColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accentColor, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  // ---- ROLE & PERMISSIONS CARD ----
  Widget _buildRoleCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Role & Permissions'),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // role info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dispatcher',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Can upload OFPs, view analytics, and manage pilot data',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // permission chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPermissionChip(
                          Icons.upload_file_rounded,
                          'Upload OFPs',
                        ),
                        _buildPermissionChip(
                          Icons.analytics_rounded,
                          'View Analytics',
                        ),
                        _buildPermissionChip(
                          Icons.people_outline_rounded,
                          'Manage Pilots',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // active badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accentColor.withOpacity(0.25)),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _borderColor, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Contact your administrator to change your role.',
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---- NOTIFICATIONS CARD ----
  Widget _buildNotificationsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Notifications'),
          const SizedBox(height: 20),
          _buildToggleRow(
            label: 'Notifica 1',
            value: _emailAlerts,
            onChanged: (v) {
              setState(() => _emailAlerts = v);
              _updateNotification('email_alerts', v);
            },
          ),
          const Divider(color: _borderColor, thickness: 1, height: 32),
          _buildToggleRow(
            label: 'Notifica 2',
            value: _weeklySummary,
            onChanged: (v) {
              setState(() => _weeklySummary = v);
              _updateNotification('weekly_summary', v);
            },
          ),
          const Divider(color: _borderColor, thickness: 1, height: 32),
          _buildToggleRow(
            label: 'Notifica 3',
            value: _pilotAnomalies,
            onChanged: (v) {
              setState(() => _pilotAnomalies = v);
              _updateNotification('pilot_anomalies', v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _accentColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFD1D5DB),
        ),
      ],
    );
  }
}
