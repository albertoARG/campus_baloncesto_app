import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_post_model.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class BlogRepository {
  final SupabaseClient _supabaseClient;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  BlogRepository(this._supabaseClient);

  Future<List<BlogPostModel>> getPosts() async {
    final response = await _supabaseClient
        .from('blog_posts')
        .select('*, users(nombre, apellidos)')
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => BlogPostModel.fromJson(json)).toList();
  }

  Future<void> createPost(String title, String content, String authorId, XFile image, {List<XFile>? galleryImages}) async {
    // 1. Upload cover to Cloudinary
    final imageUrl = await _cloudinaryService.uploadImage(image);
    if (imageUrl == null) {
      throw Exception('Fallo al subir la imagen principal a Cloudinary');
    }

    // Upload gallery images if any
    List<String> imageUrls = [];
    if (galleryImages != null && galleryImages.isNotEmpty) {
      for (var img in galleryImages) {
        final url = await _cloudinaryService.uploadImage(img);
        if (url != null) {
          imageUrls.add(url);
        } else {
          throw Exception('La imagen principal se subió, pero una de las fotos extra falló.');
        }
      }
    }

    // 2. Save metadata to Supabase
    final data = {
      'title': title,
      'content': content,
      'image_url': imageUrl,
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
      'author_id': authorId,
    };
    await _supabaseClient.from('blog_posts').insert(data);
  }

  Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    required List<String> existingImageUrls,
    List<XFile>? newGalleryImages,
  }) async {
    List<String> imageUrls = List.from(existingImageUrls);
    
    // Upload new gallery images if any
    if (newGalleryImages != null && newGalleryImages.isNotEmpty) {
      for (var img in newGalleryImages) {
        final url = await _cloudinaryService.uploadImage(img);
        if (url != null) {
          imageUrls.add(url);
        } else {
          throw Exception('Hubo un error al subir alguna de las nuevas fotos a la nube.');
        }
      }
    }

    final data = {
      'title': title,
      'content': content,
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
    };

    // Debug: ver qué datos se envían
    print('[BlogRepository.updatePost] id=$id, data=$data');

    final response = await _supabaseClient
        .from('blog_posts')
        .update(data)
        .eq('id', id)
        .select();

    print('[BlogRepository.updatePost] response=$response');

    if (response.isEmpty) {
      throw Exception(
        'El update no afectó a ninguna fila. '
        'Verifica los permisos RLS o que el ID "$id" existe en blog_posts.'
      );
    }
  }

  Future<void> deletePost(String id) async {
    await _supabaseClient.from('blog_posts').delete().eq('id', id);
  }
}
