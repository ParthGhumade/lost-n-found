import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../models.dart';
import '../api_service.dart';

class ProfileScreen extends StatefulWidget {
  final ContactProfile? initialProfile;
  final String? email;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    this.initialProfile,
    this.email,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ContactProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (_profile == null) {
      _fetchProfile();
    }
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProfile != null && widget.initialProfile != _profile) {
      setState(() {
        _profile = widget.initialProfile;
      });
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await apiService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Campus Lost & Found?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.onSignOut != null) {
        widget.onSignOut!();
      } else {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? email = widget.email;
    if (email == null) {
      try {
        email = Supabase.instance.client.auth.currentUser?.email;
      } catch (_) {}
    }
    email ??= 'test@campus.edu';
    final name = _profile?.name.isNotEmpty == true ? _profile!.name : 'Campus Student';
    final studentClass = _profile?.studentClass ?? 'Class Unassigned';
    final branch = _profile?.branch ?? 'Branch Unassigned';
    final phone = _profile?.contactNumber.isNotEmpty == true ? _profile!.contactNumber : 'Not set';

    final initials = name
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_isLoading && _profile == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null && _profile == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load profile: $_errorMessage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.danger),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _fetchProfile,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Avatar & Identity Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryContainer,
                            child: Text(
                              initials.isNotEmpty ? initials : 'ST',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    '$studentClass • $branch',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Academic & Contact Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Contact Number',
                            value: phone,
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.school_outlined,
                            label: 'Academic Program',
                            value: '$branch ($studentClass)',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.verified_user_outlined,
                            label: 'Verification Status',
                            value: 'Campus Verified Student',
                            valueColor: AppTheme.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Out Action
                    OutlinedButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: BorderSide(color: AppTheme.danger.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
