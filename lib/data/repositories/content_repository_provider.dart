import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_providers.dart';
import '../../domain/repositories/content_repository.dart';
import '../local/database_provider.dart';
import 'content_repository_impl.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseProvider),
  );
});
