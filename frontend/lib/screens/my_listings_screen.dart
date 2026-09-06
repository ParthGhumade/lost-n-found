import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../models.dart';
import '../supabase_config.dart';
import '../widgets/mutual_contact_modal.dart';

class MyListingsScreen extends StatefulWidget {
  final VoidCallback? onRequestReportItem;
  final List<LostItem>? initialListings;

  const MyListingsScreen({
    super.key,
    this.onRequestReportItem,
    this.initialListings,
  });

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<LostItem> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _checkingClaimId;
  final Map<String, List<ItemClaim>> _itemClaimsCache = {};
  final Map<String, bool> _expandedItems = {};
  final Map<String, bool> _loadingClaims = {};
  final Set<String> _deletingItemIds = {};

  RealtimeChannel? _claimsChannel;
  RealtimeChannel? _itemsChannel;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialListings != null) {
      _listings = List.from(widget.initialListings!);
      _isLoading = false;
    } else {
      _fetchListings();
    }
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _claimsChannel = apiService.subscribeToTable(
      table: SupabaseConfig.tableClaims,
      onData: (_) => _debouncedRefresh(),
      onConnectedOrReconnected: () => _debouncedRefresh(),
    );
    _itemsChannel = apiService.subscribeToTable(
      table: SupabaseConfig.tableItems,
      onData: (_) => _debouncedRefresh(),
      onConnectedOrReconnected: () => _debouncedRefresh(),
    );
  }

  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchListings(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_claimsChannel != null) apiService.unsubscribe(_claimsChannel!);
    if (_itemsChannel != null) apiService.unsubscribe(_itemsChannel!);
    super.dispose();
  }

  Future<void> _fetchListings({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await apiService.listMyListings();
      if (mounted) {
        setState(() {
          _listings = data;
          _isLoading = false;
        });

        // Re-fetch claims for any currently expanded items
        for (final item in data) {
          if (_expandedItems[item.itemId] == true) {
            _fetchClaimsForItem(item.itemId, showLoading: false);
          }
        }
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

  Future<void> _fetchClaimsForItem(String itemId, {bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loadingClaims[itemId] = true;
      });
    }

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

  Future<void> _toggleItemExpansion(String itemId) async {
    final isExpanded = _expandedItems[itemId] ?? false;
    setState(() {
      _expandedItems[itemId] = !isExpanded;
    });

    // Always fetch latest claims when expanding so finder sees up-to-date responses
    if (!isExpanded) {
      await _fetchClaimsForItem(itemId);
    }
  }

  Future<void> _checkClaimantDecision(String itemId, String claimId) async {
    setState(() {
      _checkingClaimId = claimId;
    });

    try {
      final updatedClaim = await apiService.getClaim(claimId);
      if (mounted) {
        final currentList = _itemClaimsCache[itemId] ?? [];
        final updatedList =
            currentList.map((c) => c.claimId == claimId ? updatedClaim : c).toList();
        setState(() {
          _itemClaimsCache[itemId] = updatedList;
          _checkingClaimId = null;
        });

        if (updatedClaim.status == ClaimStatus.closedByClaimant) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claimant reviewed the photo and confirmed: "It\'s Not Mine".'),
              backgroundColor: AppTheme.danger,
            ),
          );
        } else if (updatedClaim.claimantAgreedPhoto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claimant confirmed: "It\'s Mine!" Contact exchange is now open.'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claimant has not yet submitted a decision on the photo.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update claim: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteItem(LostItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text(
          'Are you sure you want to delete "${item.itemType}" found at "${item.locationFound}"?\n\n'
          'This will permanently remove the listing and any claims received for it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete Listing'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _deletingItemIds.add(item.itemId);
      });

      try {
        await apiService.deleteItemListing(item.itemId, imagePath: item.imagePath);
        if (mounted) {
          setState(() {
            _listings.removeWhere((l) => l.itemId == item.itemId);
            _deletingItemIds.remove(item.itemId);
            _expandedItems.remove(item.itemId);
            _itemClaimsCache.remove(item.itemId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _deletingItemIds.remove(item.itemId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete listing: $e'),
              backgroundColor: AppTheme.danger,
            ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(width: 6),
                        if (_deletingItemIds.contains(item.itemId))
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                            tooltip: 'Delete Listing',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            splashRadius: 18,
                            onPressed: () => _confirmDeleteItem(item),
                          ),
                      ],
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
                    if (_deletingItemIds.contains(item.itemId))
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _confirmDeleteItem(item),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                      ),
                    const SizedBox(width: 4),
                    if (isExpanded) ...[
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh claims',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _fetchClaimsForItem(item.itemId),
                      ),
                      const SizedBox(width: 4),
                    ],
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
              _buildClaimStatusBadge(claim),
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
          ] else if (claim.status == ClaimStatus.claimVerified) ...[
            if (claim.claimantAgreedPhoto)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                            'Claimant Confirmed: "It\'s Mine!"',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Both parties verified the match. You can now exchange contact information.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        MutualContactModal.show(
                          context,
                          claimId: claim.claimId,
                          viewerRole: ContactViewerRole.finder,
                          onCollected: () => _fetchListings(),
                        );
                      },
                      icon: const Icon(Icons.handshake_outlined, size: 16),
                      label: const Text('Contact Exchange'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top, color: AppTheme.warning, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo Revealed — Awaiting Claimant',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You verified the description. Waiting for the claimant to review the photo and mark if it is theirs.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      softWrap: true,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _checkingClaimId == claim.claimId
                          ? null
                          : () => _checkClaimantDecision(item.itemId, claim.claimId),
                      icon: _checkingClaimId == claim.claimId
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(
                        _checkingClaimId == claim.claimId
                            ? 'Checking Status...'
                            : 'Check Claimant Decision',
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
          ] else if (claim.status == ClaimStatus.closedByClaimant) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Claimant Confirmed: Not Mine',
                          style: TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The claimant viewed the photo and confirmed this is not their lost item. This claim has been closed.',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (claim.status == ClaimStatus.collected) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'Item has been collected.',
                  style: TextStyle(fontSize: 12, color: AppTheme.success),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    MutualContactModal.show(
                      context,
                      claimId: claim.claimId,
                      viewerRole: ContactViewerRole.finder,
                      onCollected: () => _fetchListings(),
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('View Contact'),
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

  Widget _buildClaimStatusBadge(ItemClaim claim) {
    Color bg;
    Color fg;
    String label;

    switch (claim.status) {
      case ClaimStatus.pending:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        label = 'Pending Review';
        break;
      case ClaimStatus.claimVerified:
        if (claim.claimantAgreedPhoto) {
          bg = AppTheme.successBg;
          fg = AppTheme.success;
          label = 'Photo Confirmed';
        } else {
          bg = AppTheme.surfaceMuted;
          fg = AppTheme.primary;
          label = 'Photo Revealed';
        }
        break;
      case ClaimStatus.claimRejected:
        bg = AppTheme.dangerBg;
        fg = AppTheme.danger;
        label = 'Rejected';
        break;
      case ClaimStatus.closedByClaimant:
        bg = AppTheme.dangerBg;
        fg = AppTheme.danger;
        label = 'Not Their Item';
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
