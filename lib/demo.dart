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

  runApp(const MaterialApp(home: ImageUploadTest()));
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
    if (pickedFile == null) return;

    // Load bytes (works on both web and mobile)
    final bytes = await pickedFile.readAsBytes();
    fileName = pickedFile.name;

    setState(() {
      selectedBytes = bytes;
      isUploading = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id ?? 'test-user';
      final filePath = '$userId/$fileName';

      // Upload bytes to Supabase
      final response = await supabase.storage
          .from('item-images')
          .uploadBinary(filePath, bytes);

      if (response.isEmpty) {
        throw Exception('Upload failed — empty response.');
      }

      final publicUrl =
          supabase.storage.from('item-images').getPublicUrl(filePath);

      setState(() {
        uploadedImageUrl = publicUrl;
        isUploading = false;
      });

      debugPrint('✅ Upload successful! Public URL: $publicUrl');
    } catch (error) {
      debugPrint('❌ Upload failed: $error');
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Image Upload Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedBytes != null)
              Image.memory(selectedBytes!, height: 150),
            if (isUploading) const CircularProgressIndicator(),
            if (uploadedImageUrl != null)
              Column(
                children: [
                  const SizedBox(height: 10),
                  const Text('Uploaded Image:'),
                  Image.network(uploadedImageUrl!, height: 150),
                  SelectableText(uploadedImageUrl!),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : pickAndUploadImage,
              child: const Text('Pick & Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
