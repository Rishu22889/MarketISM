import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../models/item.dart';
import '../../config/supabase_config.dart';
import '../../services/image_service.dart';
import '../../widgets/cached_network_image.dart';

class EditItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  ItemCategory _selectedCategory = ItemCategory.electronics;
  ItemCondition _selectedCondition = ItemCondition.good;
  List<XFile> _selectedImages = [];
  List<String> _imagesToDelete = [];
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _animationController = AnimationController(
      duration: ModernTheme.animationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _initializeForm() {
    _titleController.text = widget.item['title'] ?? '';
    _descriptionController.text = widget.item['description'] ?? '';
    _priceController.text = widget.item['price']?.toString() ?? '';
    
    // Set category
    try {
      _selectedCategory = ItemCategory.values.firstWhere(
        (cat) => cat.name == widget.item['category'],
        orElse: () => ItemCategory.electronics,
      );
    } catch (e) {
      _selectedCategory = ItemCategory.electronics;
    }
    
    // Set condition
    try {
      _selectedCondition = ItemCondition.values.firstWhere(
        (cond) => cond.name == widget.item['condition'],
        orElse: () => ItemCondition.good,
      );
    } catch (e) {
      _selectedCondition = ItemCondition.good;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? ModernTheme.backgroundDark : ModernTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateItem,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ModernTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Images Section
                _buildCurrentImagesSection(),
                const SizedBox(height: ModernTheme.spacing24),
                
                // Add New Images Section
                _buildNewImagesSection(),
                const SizedBox(height: ModernTheme.spacing24),
                
                // Title Field
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'What are you selling?',
                  icon: Icons.title,
                  maxLength: 80,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ModernTheme.spacing16),
                
                // Price Field
                _buildTextField(
                  controller: _priceController,
                  label: 'Price (₹)',
                  hint: 'Enter price in rupees',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ModernTheme.spacing16),
                
                // Category Dropdown
                _buildDropdown<ItemCategory>(
                  label: 'Category',
                  value: _selectedCategory,
                  items: ItemCategory.values,
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                  itemBuilder: (category) => _getCategoryName(category),
                  icon: Icons.category,
                ),
                const SizedBox(height: ModernTheme.spacing16),
                
                // Condition Dropdown
                _buildDropdown<ItemCondition>(
                  label: 'Condition',
                  value: _selectedCondition,
                  items: ItemCondition.values,
                  onChanged: (value) => setState(() => _selectedCondition = value!),
                  itemBuilder: (condition) => _getConditionName(condition),
                  icon: Icons.star,
                ),
                const SizedBox(height: ModernTheme.spacing16),
                
                // Description Field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your item in detail...',
                  icon: Icons.description,
                  maxLines: 5,
                  maxLength: 600,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ModernTheme.spacing32),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateItem,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Updating...' : 'Update Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModernTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: ModernTheme.spacing16),
                
                // Delete Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _showDeleteDialog,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ModernTheme.errorRed,
                      side: BorderSide(color: ModernTheme.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentImagesSection() {
    final images = List<String>.from(widget.item['images'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Images',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacing12),
        if (images.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No images available', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeCurrentImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: ModernTheme.errorRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNewImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Images',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacing8),
        Text(
          'Add up to 5 new photos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: ModernTheme.spacing12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Photo Button
              if (_selectedImages.length < 5)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      border: Border.all(
                        color: ModernTheme.primaryBlue.withOpacity(0.3),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: ModernTheme.primaryBlue,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModernTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Selected Images
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                        child: kIsWeb
                            ? Image.network(
                                image.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: ModernTheme.errorRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacing8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ModernTheme.primaryBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              borderSide: BorderSide(color: ModernTheme.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacing8),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ModernTheme.primaryBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              borderSide: BorderSide(color: ModernTheme.primaryBlue, width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final remainingSlots = 5 - _selectedImages.length;
          _selectedImages.addAll(images.take(remainingSlots));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeCurrentImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: ModernTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Remove Image'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this image? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final images = List<String>.from(widget.item['images'] ?? []);
                if (index < images.length) {
                  // Mark image for deletion
                  _imagesToDelete.add(images[index]);
                  images.removeAt(index);
                  widget.item['images'] = images;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Image will be removed when you save changes'),
                        ],
                      ),
                      backgroundColor: ModernTheme.warningAmber,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.errorRed,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory.name,
        'condition': _selectedCondition.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Handle image changes
      final currentImages = List<String>.from(widget.item['images'] ?? []);
      
      // Delete removed images from storage
      if (_imagesToDelete.isNotEmpty) {
        await ImageService.deleteImages(_imagesToDelete);
        // Remove deleted images from current list
        currentImages.removeWhere((url) => _imagesToDelete.contains(url));
      }
      
      // Upload new images if any
      if (_selectedImages.isNotEmpty) {
        final itemId = widget.item['id'].toString();
        final newImageUrls = await ImageService.uploadImages(_selectedImages, itemId);
        currentImages.addAll(newImageUrls);
      }
      
      updateData['images'] = currentImages;

      // Update item in Supabase
      await SupabaseConfig.client
          .from('items')
          .update(updateData)
          .eq('id', widget.item['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Item updated successfully!'),
            ],
          ),
          backgroundColor: ModernTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error updating item: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: ModernTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Delete Item'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    setState(() => _isLoading = true);
    
    try {
      await SupabaseConfig.client
          .from('items')
          .update({'status': 'deleted'})
          .eq('id', widget.item['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Item deleted successfully'),
            ],
          ),
          backgroundColor: ModernTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error deleting item: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCategoryName(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.cycles:
        return 'Cycles';
      case ItemCategory.essentials:
        return 'Essentials';
      case ItemCategory.others:
        return 'Others';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.furniture:
        return 'Furniture';
      case ItemCategory.sports:
        return 'Sports';
      case ItemCategory.other:
        return 'Other';
    }
  }

  String _getConditionName(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.new_item:
        return 'Brand New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}