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

class SupabasePostItemScreen extends StatefulWidget {
  const SupabasePostItemScreen({super.key});

  @override
  State<SupabasePostItemScreen> createState() => _SupabasePostItemScreenState();
}

class _SupabasePostItemScreenState extends State<SupabasePostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  ItemCategory _selectedCategory = ItemCategory.electronics;
  ItemCondition _selectedCondition = ItemCondition.good;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Item'),
        backgroundColor: ModernTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _postItem,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'POST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Consumer<SupabaseAuthProvider>(
        builder: (context, authProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Images Section
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  
                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'What are you selling?',
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
                  const SizedBox(height: 16),
                  
                  // Price Field
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price (₹)',
                    hint: 'Enter price in rupees',
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
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  _buildDropdown<ItemCategory>(
                    label: 'Category',
                    value: _selectedCategory,
                    items: ItemCategory.values,
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                    itemBuilder: (category) => _getCategoryName(category),
                  ),
                  const SizedBox(height: 16),
                  
                  // Condition Dropdown
                  _buildDropdown<ItemCondition>(
                    label: 'Condition',
                    value: _selectedCondition,
                    items: ItemCondition.values,
                    onChanged: (value) => setState(() => _selectedCondition = value!),
                    itemBuilder: (condition) => _getConditionName(condition),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description Field
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your item in detail...',
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
                  const SizedBox(height: 32),
                  
                  // Post Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _postItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Post Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 5 photos',
          style: TextStyle(
            fontSize: 14,
            color: ModernTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
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
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, 
                             color: ModernTheme.primaryBlue, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModernTheme.primaryBlue,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ModernTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ModernTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
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

  Future<void> _postItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please add at least one photo'),
            ],
          ),
          backgroundColor: ModernTheme.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userProfile = authProvider.userProfile;
      
      if (user == null || userProfile == null) {
        throw Exception('User not authenticated');
      }

      // Show upload progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Uploading ${_selectedImages.length} images...'),
            ],
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: ModernTheme.primaryBlue,
        ),
      );

      // Upload images to Supabase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        debugPrint('📤 Uploading ${_selectedImages.length} images...');
        final tempItemId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await ImageService.uploadImages(_selectedImages, tempItemId);
        
        debugPrint('✅ Uploaded ${imageUrls.length} images successfully');
        debugPrint('🔗 Image URLs: $imageUrls');
        
        if (imageUrls.isEmpty) {
          throw Exception('Failed to upload images. Please check your internet connection and try again.');
        }
        
        if (imageUrls.length < _selectedImages.length) {
          debugPrint('⚠️ Warning: Only ${imageUrls.length} out of ${_selectedImages.length} images uploaded successfully');
        }
      }

      // Clear the upload progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Insert item into Supabase
      final response = await SupabaseConfig.client.from('items').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory.name,
        'condition': _selectedCondition.name,
        'seller_id': user.id,
        'seller_name': userProfile.name,
        'seller_email': userProfile.email,
        'images': imageUrls,
        'status': 'available',
      }).select();

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Item posted successfully!'),
              ],
            ),
            backgroundColor: ModernTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save item to database');
      }
    } catch (e) {
      debugPrint('❌ Error posting item: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error posting item: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
          duration: const Duration(seconds: 5),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}