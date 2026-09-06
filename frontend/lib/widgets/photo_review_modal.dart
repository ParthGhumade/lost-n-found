import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../models.dart';

class PhotoReviewModal extends StatefulWidget {
  final ItemClaim claim;
  final VoidCallback onDecisionMade;
  final void Function(String claimId)? onShowContactExchange;

  const PhotoReviewModal({
    super.key,
    required this.claim,
    required this.onDecisionMade,
    this.onShowContactExchange,
  });

  static Future<void> show(
    BuildContext context, {
    required ItemClaim claim,
    required VoidCallback onDecisionMade,
    void Function(String claimId)? onShowContactExchange,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PhotoReviewModal(
        claim: claim,
        onDecisionMade: onDecisionMade,
        onShowContactExchange: onShowContactExchange,
      ),
    );
  }

  @override
  State<PhotoReviewModal> createState() => _PhotoReviewModalState();
}

class _PhotoReviewModalState extends State<PhotoReviewModal> {
  String? _signedUrl;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessingDecision = false;

  @override
  void initState() {
    super.initState();
    _fetchSignedUrl();
  }

  Future<void> _fetchSignedUrl() async {
    try {
      final url = await apiService.getClaimImageSignedUrl(widget.claim.claimId);
      if (mounted) {
        setState(() {
          _signedUrl = url;
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

  Future<void> _handleDecision(bool isMine) async {
    setState(() {
      _isProcessingDecision = true;
    });

    try {
      await apiService.decideClaimPhoto(
        claimId: widget.claim.claimId,
        isMine: isMine,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDecisionMade();
        if (isMine && widget.onShowContactExchange != null) {
          widget.onShowContactExchange!(widget.claim.claimId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isMine
                    ? 'Confirmed! Opening contact exchange.'
                    : 'Claim closed. Thank you for confirming.',
              ),
              backgroundColor: isMine ? AppTheme.success : AppTheme.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingDecision = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemType = widget.claim.item?.itemType ?? 'Lost Item';
    final location = widget.claim.item?.locationFound ?? 'Campus';
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: screenHeight * 0.88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review Photo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$itemType • Found at $location',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isProcessingDecision ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Responsive Image display
              Container(
                width: double.infinity,
                height: (screenHeight * 0.32).clamp(160.0, 300.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(height: 12),
                              Text('Loading verified photo...', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Could not load photo: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                                ),
                              ),
                            )
                          : _signedUrl != null
                              ? Image.network(
                                  _signedUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) => const Center(
                                    child: Text('Failed to render photo.', style: TextStyle(color: AppTheme.danger)),
                                  ),
                                )
                              : const Center(
                                  child: Text('No image available.'),
                                ),
                ),
                const SizedBox(height: 14),

              // Prompt & Information
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Confirm if this is your item to exchange contact details.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Binary Action Buttons
              if (_isProcessingDecision)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: _isLoading || _errorMessage != null ? null : () => _handleDecision(true),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("It's Mine"),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleDecision(false),
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: AppTheme.danger),
                  label: const Text('Not Mine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
