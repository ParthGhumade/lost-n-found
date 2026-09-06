import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../models.dart';

class MutualContactModal extends StatefulWidget {
  final String claimId;
  final VoidCallback? onCollected;

  const MutualContactModal({
    super.key,
    required this.claimId,
    this.onCollected,
  });

  static Future<void> show(
    BuildContext context, {
    required String claimId,
    VoidCallback? onCollected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MutualContactModal(
        claimId: claimId,
        onCollected: onCollected,
      ),
    );
  }

  @override
  State<MutualContactModal> createState() => _MutualContactModalState();
}

class _MutualContactModalState extends State<MutualContactModal> {
  MutualContactExchange? _exchange;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMarkingCollected = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final data = await apiService.getMutualContact(widget.claimId);
      if (mounted) {
        setState(() {
          _exchange = data;
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

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer for $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Strip non-numeric characters for WhatsApp link
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch WhatsApp for $phoneNumber')),
        );
      }
    }
  }

  Future<void> _markCollected() async {
    setState(() {
      _isMarkingCollected = true;
    });

    try {
      await apiService.markClaimCollected(widget.claimId);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCollected?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as collected! Case resolved successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMarkingCollected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.handshake_outlined, color: AppTheme.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contact Exchange',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 28),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load contact exchange: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_exchange != null) ...[
                // Finder Contact Card
                _buildProfileCard(
                  title: "Finder's Details",
                  icon: Icons.person_search_outlined,
                  accentColor: AppTheme.primary,
                  profile: _exchange!.finder,
                ),
                const SizedBox(height: 14),

                // Claimant Contact Card
                _buildProfileCard(
                  title: "Claimant's Details",
                  icon: Icons.person_pin_outlined,
                  accentColor: AppTheme.textSecondary,
                  profile: _exchange!.claimant,
                ),
                const SizedBox(height: 16),

                // Campus Safety Tip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safety Tip: Meet in a public campus spot (e.g. library or security desk).',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mark Collected Action
                if (_exchange!.status == ClaimStatus.collected)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'This item was marked as collected and returned.',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isMarkingCollected ? null : _markCollected,
                    icon: _isMarkingCollected
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isMarkingCollected ? 'Updating...' : 'Mark as Collected'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required ContactProfile profile,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.name.isNotEmpty ? profile.name : 'Campus Student',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.studentClass} • ${profile.branch}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: profile.contactNumber.isNotEmpty
                    ? () => _makeCall(profile.contactNumber)
                    : null,
                icon: const Icon(Icons.call, size: 16),
                label: Text(
                  profile.contactNumber.isNotEmpty ? profile.contactNumber : 'No Phone',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              FilledButton.icon(
                onPressed: profile.contactNumber.isNotEmpty
                    ? () => _openWhatsApp(profile.contactNumber)
                    : null,
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
