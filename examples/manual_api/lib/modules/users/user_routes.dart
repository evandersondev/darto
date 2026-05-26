import 'package:darto/darto.dart';
import 'package:manual_api/logger.dart';
import 'package:manual_api/modules/users/user_service.dart';

import 'create_user_dto.dart';

void userRoutes(Router router) {
  final userService = UserService();

  router.get('/', [], (Context c) async {
    final users = await userService.getAllUsers();

    return c.ok(users.map((user) => user.toJson()).toList());
  });

  router.post('/', [], (Context c) async {
    final dto = CreateUserDto.fromJson(await c.req.json());
    final user = await userService.createUser(dto);

    log('User created:', ['ID: ${user.id},', 'Name: ${user.name}']);

    return c.created(user.toJson());
  });

  router.get('/:id', [], (Context c) async {
    final id = c.req.param('id');
    final user = await userService.getUserById(id!);

    if (user == null) {
      return c.notFound();
    }

    return c.ok(user.toJson());
  });

  router.route("admin", (admin) {
    admin.get("/dash", [], (c) {
      // c.req.arr
      return c.text("Deu certo");
    });
  });
}
