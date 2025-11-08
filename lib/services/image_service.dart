import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ImageService {
  static const String bucketName = 'item-images';
  
  /// Upload image to Supabase Storage and return public URL
  static Future<String?> uploadImage(XFile imageFile, String itemId) async {
    try {
      debugPrint('🔄 Starting image upload for item: $itemId');
      
      // Generate unique filename with proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String extension = 'jpg'; // Default extension
      
      // Try to get extension from file name or MIME type
      if (imageFile.name.contains('.')) {
        extension = imageFile.name.split('.').last.toLowerCase();
      } else if (imageFile.mimeType != null) {
        if (imageFile.mimeType!.contains('png')) extension = 'png';
        else if (imageFile.mimeType!.contains('jpeg') || imageFile.mimeType!.contains('jpg')) extension = 'jpg';
        else if (imageFile.mimeType!.contains('webp')) extension = 'webp';
      }
      
      final fileName = '${itemId}_${timestamp}.$extension';
      debugPrint('📁 Generated filename: $fileName');
      
      Uint8List imageBytes;
      
      if (kIsWeb) {
        // For web, read as bytes
        imageBytes = await imageFile.readAsBytes();
      } else {
        // For mobile, read file
        final file = File(imageFile.path);
        imageBytes = await file.readAsBytes();
      }
      
      debugPrint('📊 Image size: ${imageBytes.length} bytes');
      
      // Determine content type based on extension
      String contentType = 'image/jpeg'; // Default
      switch (extension.toLowerCase()) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
      }
      
      debugPrint('📋 Content type: $contentType');
      
      // Upload to Supabase Storage with proper content type
      final response = await SupabaseConfig.client.storage
          .from(bucketName)
          .uploadBinary(
            fileName, 
            imageBytes, 
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );
      
      debugPrint('📤 Upload response: $response');
      
      if (response.isNotEmpty) {
        // Get public URL
        final publicUrl = SupabaseConfig.client.storage
            .from(bucketName)
            .getPublicUrl(fileName);
        
        debugPrint('🔗 Generated public URL: $publicUrl');
        return publicUrl;
      }
      
      debugPrint('❌ Upload failed: Empty response');
      return null;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }
  
  /// Upload multiple images and return list of URLs
  static Future<List<String>> uploadImages(List<XFile> imageFiles, String itemId) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(imageFiles[i], '${itemId}_$i');
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }
  
  /// Delete image from Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.last;
        
        await SupabaseConfig.client.storage
            .from(bucketName)
            .remove([fileName]);
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }
  
  /// Delete multiple images
  static Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
  
  /// Get optimized image URL with resize parameters
  static String getOptimizedImageUrl(String originalUrl, {int? width, int? height}) {
    if (originalUrl.isEmpty) return originalUrl;
    
    try {
      final uri = Uri.parse(originalUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      
      if (width != null && width.isFinite) queryParams['width'] = width.toString();
      if (height != null && height.isFinite) queryParams['height'] = height.toString();
      queryParams['resize'] = 'cover';
      queryParams['quality'] = '80';
      
      return uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      return originalUrl;
    }
  }
  
  /// Create placeholder image URL
  static String getPlaceholderUrl({int width = 300, int height = 300}) {
    return 'https://via.placeholder.com/${width}x${height}/E3F2FD/1976D2?text=No+Image';
  }
  
  /// Check if URL is a valid image URL
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      final isValid = uri.isAbsolute && 
             (url.contains('supabase') || url.contains('placeholder') || url.contains('via.placeholder'));
      
      debugPrint('🔍 Validating URL: $url -> $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ URL validation error: $e');
      return false;
    }
  }
  
  /// Get a fallback image URL when the original fails
  static String getFallbackImageUrl() {
    return 'https://via.placeholder.com/300x300/E3F2FD/1976D2?text=No+Image';
  }
}