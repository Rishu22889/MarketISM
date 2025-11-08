import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://nurrxoppjoodhxumnglm.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51cnJ4b3Bwam9vZGh4dW1uZ2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyODEzNTcsImV4cCI6MjA3Nzg1NzM1N30.rDtHVRaa0SxmUJ_ZpMfowva0UJcaBXfRAZ0AzZDCPeA", 
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ImageUploadTest(),
  ));
}

class ImageUploadTest extends StatefulWidget {
  const ImageUploadTest({Key? key}) : super(key: key);

  @override
  State<ImageUploadTest> createState() => _ImageUploadTestState();
}

class _ImageUploadTestState extends State<ImageUploadTest> {
  final SupabaseClient supabase = Supabase.instance.client;
  Uint8List? selectedBytes;
  String? uploadedImageUrl;
  bool isUploading = false;
  String? fileName;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      debugPrint('❌ No image selected.');
      return;
    }

    // Load bytes for web compatibility
    final bytes = await pickedFile.readAsBytes();
    fileName = pickedFile.name;

    setState(() {
      selectedBytes = bytes;
      isUploading = true;
    });

    try {
      // Generate a unique path per user or test session
      final userId = supabase.auth.currentUser?.id ?? 'test-user';
      final filePath = '$userId/$fileName';

      debugPrint('📤 Uploading to: item-images/$filePath');

      // Upload bytes to Supabase Storage
      final response = await supabase.storage
          .from('item-images')
          .uploadBinary(filePath, bytes);

      debugPrint('📦 Upload response: $response');

      // Get public URL
      final publicUrl =
          supabase.storage.from('item-images').getPublicUrl(filePath);

      setState(() {
        uploadedImageUrl = publicUrl;
        isUploading = false;
      });

      debugPrint('✅ Upload successful! Public URL: $publicUrl');
    } catch (error) {
      debugPrint('❌ Upload failed: $error');

      if (error is StorageException) {
        debugPrint('⚠️ StorageException: ${error.message}');
        debugPrint('Status Code: ${error.statusCode}');
      }

      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Image Upload Test'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedBytes != null)
                Image.memory(selectedBytes!, height: 180),
              const SizedBox(height: 20),
              if (isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Uploading image... Please wait"),
                  ],
                ),
              if (uploadedImageUrl != null && !isUploading)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text('✅ Uploaded Image:'),
                    const SizedBox(height: 10),
                    Image.network(uploadedImageUrl!, height: 180),
                    const SizedBox(height: 10),
                    SelectableText(
                      uploadedImageUrl!,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isUploading ? null : pickAndUploadImage,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Pick & Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
