import 'dart:typed_data';

import 'package:postgres/postgres.dart';

import '../db/postgres_db.dart';

class UserProfileRepository {
  Future<void> saveProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final pool = await PostgresDb.instance.pool;
    final result = await pool.execute(
      Sql.named('''
        UPDATE users
        SET profile_image_data = @image, updated_at = NOW()
        WHERE id = @userId
      '''),
      parameters: {'image': imageBytes, 'userId': userId},
    );
    if (result.affectedRows == 0) {
      throw StateError('The account could not be found.');
    }
  }
}
