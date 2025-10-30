import '../models/user_model.dart';
import 'database_service.dart';
import 'pin_store.dart';

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
    // Look up the user id from the encrypted PinStore
    final userId = PinStore.instance.getUserIdForPin(pin);
    if (userId == null) return null;
    final user = await getById(userId);
    if (user == null) return null;
    return user.status == UserStatus.active ? user : null;
  }
}
