import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tablon_post_model.dart';

class TablonRepository {
  final SupabaseClient _supabaseClient;
  TablonRepository(this._supabaseClient);

  Future<List<TablonPostModel>> getPosts({bool isStaff = false}) async {
    var query = _supabaseClient
        .from('tablon_posts')
        .select('*, users(nombre, apellidos)');
        
    if (!isStaff) {
      query = query.eq('is_staff_only', false);
    }
        
    final response = await query.order('created_at', ascending: false);
        
    return (response as List).map((json) => TablonPostModel.fromJson(json)).toList();
  }

  Future<void> createPost(String title, String content, String authorId, {bool isStaffOnly = false}) async {
    final data = {
      'title': title,
      'content': content,
      'author_id': authorId,
      'is_staff_only': isStaffOnly,
    };
    await _supabaseClient.from('tablon_posts').insert(data);
  }

  Future<void> deletePost(String id) async {
    await _supabaseClient.from('tablon_posts').delete().eq('id', id);
  }
}
