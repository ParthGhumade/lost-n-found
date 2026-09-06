import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/mutual_contact_modal.dart';

class MyListingsScreen extends StatefulWidget {
  final VoidCallback? onRequestReportItem;

  const MyListingsScreen({super.key, this.onRequestReportItem});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<LostItem> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, List<ItemClaim>> _itemClaimsCache = {};
  final Map<String, bool> _expandedItems = {};
  final Map<String, bool> _loadingClaims = {};

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await apiService.listMyListings();
      if (mounted) {
        setState(() {
          _listings = data;
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

  Future<void> _toggleItemExpansion(String itemId) async {
    final isExpanded = _expandedItems[itemId] ?? false;
    setState(() {
      _expandedItems[itemId] = !isExpanded;
    });

    if (!isExpanded && !_itemClaimsCache.containsKey(itemId)) {
      setState(() {
        _loadingClaims[itemId] = true;
      });

      try {
        final claims = await apiService.listClaimsForItem(itemId);
        if (mounted) {
          setState(() {
            _itemClaimsCache[itemId] = claims;
            _loadingClaims[itemId] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingClaims[itemId] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load claims: $e')),
          );
        }
      }
    }
  }

  Future<void> _reviewClaim(String itemId, String claimId, bool isVerified) async {
    try {
      await apiService.reviewClaim(claimId: claimId, isVerified: isVerified);

      // Refresh claims for this item
      final updatedClaims = await apiService.listClaimsForItem(itemId);
      if (mounted) {
        setState(() {
          _itemClaimsCache[itemId] = updatedClaims;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified
                  ? 'Claim description verified! Photo revealed to claimant.'
                  : 'Claim rejected.',
            ),
            backgroundColor: isVerified ? AppTheme.success : AppTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _fetchListings,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'My Reported Items',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.onRequestReportItem != null)
                          FilledButton.icon(
                            onPressed: widget.onRequestReportItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Report Found'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
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
                          'Failed to load listings: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchListings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_listings.isEmpty)
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
                          child: const Icon(Icons.playlist_add_check, size: 48, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Reported Items Yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Found an item on campus? Report it to help its owner find it safely.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        if (widget.onRequestReportItem != null)
                          FilledButton.icon(
                            onPressed: widget.onRequestReportItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Report Found Item'),
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
                        itemCount: _listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _listings[index];
                          return _buildListingCard(item);
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

  Widget _buildListingCard(LostItem item) {
    final isExpanded = _expandedItems[item.itemId] ?? false;
    final claims = _itemClaimsCache[item.itemId];
    final isLoadingClaims = _loadingClaims[item.itemId] ?? false;
    final formattedDate =
        '${item.dateFound.year}-${item.dateFound.month.toString().padLeft(2, '0')}-${item.dateFound.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          item.itemType,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.status == ItemStatus.returned
                            ? AppTheme.successBg
                            : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: item.status == ItemStatus.returned
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        item.status == ItemStatus.returned ? 'Returned' : 'Active Listing',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.status == ItemStatus.returned
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.locationFound,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Found on $formattedDate',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.claimsCount != null
                            ? '${item.claimsCount} Claims Received'
                            : 'Review Claims',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _toggleItemExpansion(item.itemId),
                      icon: Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                      label: Text(isExpanded ? 'Hide Claims' : 'View Claims'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Collapsible Claims Section
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: AppTheme.surfaceSubtle,
              padding: const EdgeInsets.all(16),
              child: isLoadingClaims
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : claims == null || claims.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'No claims submitted for this item yet.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: claims.map((claim) => _buildClaimTile(item, claim)).toList(),
                        ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClaimTile(LostItem item, ItemClaim claim) {
    final claimantName = claim.claimant?.name ?? 'Campus Student';
    final claimantInfo = claim.claimant != null
        ? '${claim.claimant!.studentClass} • ${claim.claimant!.branch}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Claimant Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimantName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (claimantInfo.isNotEmpty)
                      Text(
                        claimantInfo,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildClaimStatusBadge(claim.status),
            ],
          ),
          const SizedBox(height: 10),

          // Claimant Submitted Description
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
          const SizedBox(height: 12),

          // Actions depending on Claim status
          if (claim.status == ClaimStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reviewClaim(item.itemId, claim.claimId, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Reject Claim'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _reviewClaim(item.itemId, claim.claimId, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Verify Description'),
                  ),
                ),
              ],
            ),
          ] else if (claim.status == ClaimStatus.claimVerified || claim.status == ClaimStatus.collected) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Description verified by you.',
                  style: TextStyle(fontSize: 12, color: AppTheme.success),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    MutualContactModal.show(
                      context,
                      claimId: claim.claimId,
                      onCollected: () => _fetchListings(),
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('Contact Exchange'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClaimStatusBadge(ClaimStatus status) {
    Color bg;
    Color fg;
    String label = status.displayLabel;

    switch (status) {
      case ClaimStatus.pending:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        label = 'Pending Review';
        break;
      case ClaimStatus.claimVerified:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        label = 'Photo Revealed';
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
        label = 'Collected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
