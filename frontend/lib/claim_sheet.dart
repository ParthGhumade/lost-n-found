import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'models.dart';

class ClaimSheet extends StatefulWidget {
  final LostItem item;
  final VoidCallback onClaimSubmitted;

  const ClaimSheet({
    super.key,
    required this.item,
    required this.onClaimSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required LostItem item,
    required VoidCallback onClaimSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClaimSheet(
        item: item,
        onClaimSubmitted: onClaimSubmitted,
      ),
    );
  }

  @override
  State<ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<ClaimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await apiService.submitClaim(
        itemId: widget.item.itemId,
        description: _descController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onClaimSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('409') || e.toString().contains('duplicate')
              ? 'You already have an active claim for this item.'
              : 'Failed to submit claim: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomInset + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Title & Close
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Claim: ${widget.item.itemType}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Found at: ${widget.item.locationFound}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Private Verification Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // soft blue
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The finder\'s photo is private. Describe unique details (brand, stickers, scratches, case color) so the finder can verify your match.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                ),
              ),

            // Description Label & Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_descController.text.length} / min 10 chars',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Description Input Field
            TextFormField(
              controller: _descController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText:
                    'E.g. Matte black Anker Soundcore Life P3 case with small surface scratch along the hinge and blue sticker on the underside.',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please describe the item';
                }
                if (val.trim().length < 10) {
                  return 'Please provide at least 10 characters of detail';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_outlined, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Claim'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

  }
}
