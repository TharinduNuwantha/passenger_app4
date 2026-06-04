import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload profile photo
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final String fileExt = path.extension(imageFile.path);
      final String fileName = '$userId-profile$fileExt';
      final String filePath = 'profile_photos/$fileName';

      // Upload file to 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final String publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Append timestamp query param to bypass client image caching
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }


  // Delete profile photo
  Future<void> deleteProfilePhoto(String filePath) async {
    try {
      await _supabase.storage.from('avatars').remove([filePath]);
    } catch (e) {
      // Ignore delete errors or handle them
    }
  }
}
