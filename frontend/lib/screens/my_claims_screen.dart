import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../models.dart';
import '../supabase_config.dart';
import '../widgets/mutual_contact_modal.dart';
import '../widgets/photo_review_modal.dart';

class MyClaimsScreen extends StatefulWidget {
  final VoidCallback? onBrowseFeed;

  const MyClaimsScreen({super.key, this.onBrowseFeed});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  List<ItemClaim> _claims = [];
  bool _isLoading = true;
  String? _errorMessage;

  RealtimeChannel? _claimsChannel;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchClaims();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _claimsChannel = apiService.subscribeToTable(
      table: SupabaseConfig.tableClaims,
      onData: (_) => _debouncedRefresh(),
    );
  }

  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchClaims(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_claimsChannel != null) apiService.unsubscribe(_claimsChannel!);
    super.dispose();
  }

  Future<void> _fetchClaims({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await apiService.listMyClaims();
      if (mounted) {
        setState(() {
          _claims = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (!silent) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _fetchClaims,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Claims',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load claims: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchClaims,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_claims.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Claims Submitted',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'When you claim an item from the Campus Feed, you can track its review progress here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        if (widget.onBrowseFeed != null)
                          FilledButton.icon(
                            onPressed: widget.onBrowseFeed,
                            icon: const Icon(Icons.search),
                            label: const Text('Browse Public Feed'),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final claim = _claims[index];
                          return _buildClaimTrackerCard(claim);
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimTrackerCard(ItemClaim claim) {
    final item = claim.item;
    final itemType = item?.itemType ?? 'Lost Item';
    final location = item?.locationFound ?? 'Campus';
    final formattedDate = claim.createdAt.toIso8601String().split('T').first;

    final isVerified = claim.status == ClaimStatus.claimVerified;
    final isCollected = claim.status == ClaimStatus.collected;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isVerified
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.border,
          width: isVerified ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Item name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildTrackerStatusBadge(claim.status),
            ],
          ),
          const SizedBox(height: 8),

          // Location & Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Found at $location',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Claimed on $formattedDate',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Claimant's Submitted Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              claim.claimDescription,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Status Callouts & Action Buttons
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.success.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Description Matched',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (claim.claimantAgreedPhoto) ...[
                    const Text(
                      'You confirmed this is your item. Reach out to the finder to coordinate.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        MutualContactModal.show(
                          context,
                          claimId: claim.claimId,
                          viewerRole: ContactViewerRole.claimant,
                          onCollected: () => _fetchClaims(),
                        );
                      },
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: const Text('Contact Exchange'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Finder verified your description. Review the photo to confirm ownership.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        PhotoReviewModal.show(
                          context,
                          claim: claim,
                          onDecisionMade: () => _fetchClaims(),
                          onShowContactExchange: (claimId) {
                            _fetchClaims();
                            MutualContactModal.show(
                              context,
                              claimId: claimId,
                              viewerRole: ContactViewerRole.claimant,
                              onCollected: () => _fetchClaims(),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.image_search_outlined, size: 18),
                      label: const Text('Review Photo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (isCollected) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.task_alt, color: AppTheme.success, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Item returned and resolved.',
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w500, fontSize: 12),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    MutualContactModal.show(
                      context,
                      claimId: claim.claimId,
                      viewerRole: ContactViewerRole.claimant,
                      onCollected: () => _fetchClaims(),
                    );
                  },
                  icon: const Icon(Icons.person_outlined, size: 16),
                  label: const Text('View Finder Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ] else if (claim.status == ClaimStatus.claimRejected) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.danger, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Finder rejected this claim (description did not match).',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (claim.status == ClaimStatus.closedByClaimant) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, color: AppTheme.textMuted, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Closed: Revealed photo was not your item.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, color: AppTheme.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending finder review. You will be notified once verified.',
                      style: TextStyle(color: AppTheme.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackerStatusBadge(ClaimStatus status) {
    Color bg;
    Color fg;
    String label = status.displayLabel;

    switch (status) {
      case ClaimStatus.pending:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        label = 'Pending Finder Review';
        break;
      case ClaimStatus.claimVerified:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        label = 'Verified (Photo Ready)';
        break;
      case ClaimStatus.claimRejected:
        bg = AppTheme.dangerBg;
        fg = AppTheme.danger;
        break;
      case ClaimStatus.closedByClaimant:
        bg = AppTheme.surfaceMuted;
        fg = AppTheme.textMuted;
        break;
      case ClaimStatus.collected:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        label = 'Item Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
