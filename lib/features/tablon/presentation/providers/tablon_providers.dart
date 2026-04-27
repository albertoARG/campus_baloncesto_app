import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/tablon_repository.dart';
import '../../data/models/tablon_post_model.dart';

final tablonRepositoryProvider = Provider<TablonRepository>((ref) {
  return TablonRepository(ref.watch(supabaseClientProvider));
});

final tablonPostsProvider = FutureProvider.autoDispose<List<TablonPostModel>>((ref) async {
  final repo = ref.watch(tablonRepositoryProvider);
  final userProfile = ref.watch(currentUserProfileProvider).value;
  final String role = userProfile?.role ?? 'visitante';
  final bool isStaff = role == 'admin' || role == 'entrenador';
  
  return repo.getPosts(isStaff: isStaff);
});
