import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
// import '../providers/item_provider.dart';
import '../theme/app_theme.dart';

class SearchFilterBar extends StatefulWidget {
  final ItemProvider itemProvider;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterTap;

  const SearchFilterBar({
    super.key,
    required this.itemProvider,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.itemProvider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryRed,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.hintTextColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryRed,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Filter button
          Container(
            decoration: BoxDecoration(
              color: widget.itemProvider.currentFilter.hasFilters
                  ? AppTheme.primaryRed
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryRed,
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: widget.onFilterTap,
              icon: Icon(
                Icons.tune,
                color: widget.itemProvider.currentFilter.hasFilters
                    ? AppTheme.cardWhite
                    : AppTheme.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ItemProvider itemProvider;

  const FilterBottomSheet({
    super.key,
    required this.itemProvider,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ItemFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.itemProvider.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Row(
            children: [
              const Text(
                'Filter Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempFilter = const ItemFilter();
                  });
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Color(0xFFFFD100),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Category filter
          _buildCategoryFilter(),
          
          const SizedBox(height: 24),
          
          // Price range filter
          _buildPriceRangeFilter(),
          
          const SizedBox(height: 32),
          
          // Apply button
          ElevatedButton(
            onPressed: () {
              widget.itemProvider.applyFilter(_tempFilter);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD100),
              foregroundColor: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // All categories chip
            FilterChip(
              label: const Text('All'),
              selected: _tempFilter.category == null,
              onSelected: (selected) {
                setState(() {
                  _tempFilter = _tempFilter.copyWith(category: null);
                });
              },
              selectedColor: const Color(0xFFFFD100),
              checkmarkColor: const Color(0xFF111111),
            ),
            
            // Individual category chips
            ...widget.itemProvider.availableCategories.map((category) {
              return FilterChip(
                label: Text(_getCategoryDisplayName(category)),
                selected: _tempFilter.category == category,
                onSelected: (selected) {
                  setState(() {
                    _tempFilter = _tempFilter.copyWith(
                      category: selected ? category : null,
                    );
                  });
                },
                selectedColor: const Color(0xFFFFD100),
                checkmarkColor: const Color(0xFF111111),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // All prices chip
            FilterChip(
              label: const Text('All Prices'),
              selected: _tempFilter.minPrice == null && _tempFilter.maxPrice == null,
              onSelected: (selected) {
                setState(() {
                  _tempFilter = _tempFilter.copyWith(
                    minPrice: null,
                    maxPrice: null,
                  );
                });
              },
              selectedColor: const Color(0xFFFFD100),
              checkmarkColor: const Color(0xFF111111),
            ),
            
            // Price range chips
            ...widget.itemProvider.priceRanges.map((range) {
              final isSelected = _tempFilter.minPrice == range.minPrice &&
                                _tempFilter.maxPrice == range.maxPrice;
              
              return FilterChip(
                label: Text(range.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _tempFilter = _tempFilter.copyWith(
                        minPrice: range.minPrice,
                        maxPrice: range.maxPrice,
                      );
                    } else {
                      _tempFilter = _tempFilter.copyWith(
                        minPrice: null,
                        maxPrice: null,
                      );
                    }
                  });
                },
                selectedColor: const Color(0xFFFFD100),
                checkmarkColor: const Color(0xFF111111),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  String _getCategoryDisplayName(ItemCategory category) {
    switch (category) {
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.cycles:
        return 'Cycles';
      case ItemCategory.essentials:
        return 'Essentials';
      case ItemCategory.others:
        return 'Others';
    }
  }
}