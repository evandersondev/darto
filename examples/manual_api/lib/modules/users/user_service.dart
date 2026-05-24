import 'package:manual_api/modules/users/user_model.dart';

import 'create_user_dto.dart';

class UserService {
  final List<UserModel> _users = [];

  Future<UserModel> createUser(CreateUserDto dto) async {
    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: dto.name,
      email: dto.email,
    );
    _users.add(newUser);
    return newUser;
  }

  Future<List<UserModel>> getAllUsers() async {
    return _users;
  }

  Future<UserModel?> getUserById(String id) async {
    print(id);
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
