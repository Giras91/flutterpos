import '../models/user_model.dart';
import 'database_service.dart';

/// Lightweight wrapper around DatabaseService to expose user-related operations.
class UserService {
  static final UserService instance = UserService._init();
  UserService._init();

  final _db = DatabaseService.instance;

  Future<List<User>> getAllUsers() => _db.getUsers();

  Future<User?> getById(String id) => _db.getUserById(id);

  Future<int> addUser(User user) => _db.insertUser(user);

  Future<int> updateUser(User user) => _db.updateUser(user);

  Future<int> deleteUser(String id) => _db.deleteUser(id);

  /// Find the first active user matching the provided PIN (exact match).
  Future<User?> findByPin(String pin) async {
    final all = await getAllUsers();
    try {
      return all.firstWhere(
        (u) => u.pin == pin && u.status == UserStatus.active,
      );
    } catch (e) {
      return null;
    }
  }
}
