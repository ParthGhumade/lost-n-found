import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_service.dart';
import '../app_theme.dart';
import '../claim_sheet.dart';
import '../models.dart';
import '../supabase_config.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback? onRequestReportItem;

  const FeedScreen({
    super.key,
    this.onRequestReportItem,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<LostItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  RealtimeChannel? _itemsChannel;
  Timer? _debounceTimer;

  final List<String> _categories = [
    'All',
    'Electronics',
    'ID Cards',
    'Keys',
    'Wallets',
    'Books',
    'Apparel',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
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
        _fetchItems(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_itemsChannel != null) apiService.unsubscribe(_itemsChannel!);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await apiService.listPublicItems(
        categoryFilter: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _items = data;
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
        onRefresh: _fetchItems,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Feed Header & Search
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            const Text(
                              'Campus Feed',
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
                        const SizedBox(height: 14),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _fetchItems(),
                          decoration: InputDecoration(
                            hintText: 'Search items, locations (e.g. library, keys, charger)...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _fetchItems();
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Horizontal Category Chips
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedCategory = cat);
                                    _fetchItems();
                                  }
                                },
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                ),
                                backgroundColor: AppTheme.surface,
                                selectedColor: AppTheme.primaryContainer,
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Item Listings
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined, color: AppTheme.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load listings: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchItems,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
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
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Found Items Listed',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Items reported by students will appear here in the live campus feed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
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
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildItemCard(context, item);
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

  Widget _buildItemCard(BuildContext context, LostItem item) {
    final formattedDate =
        '${item.dateFound.year}-${item.dateFound.month.toString().padLeft(2, '0')}-${item.dateFound.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Pill & Anti-Fraud Privacy Note
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
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppTheme.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'Photo Hidden',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.locationFound,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date Found
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.textMuted),
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
          const SizedBox(height: 16),

          // Bottom Action
          Builder(
            builder: (context) {
              final isOwnListing = item.finderContactId != null &&
                  item.finderContactId == apiService.currentUserId;

              if (isOwnListing) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_pin_circle_outlined, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Your Listing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'You cannot claim an item you reported as found',
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Your Listing'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    ClaimSheet.show(
                      context,
                      item: item,
                      onClaimSubmitted: () {
                        _fetchItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Claim submitted! You can track it under "My Claims".'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: const Text('Claim Item'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
