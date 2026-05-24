class CreateUserDto {
  final String name;
  final String email;

  CreateUserDto({required this.name, required this.email});

  factory CreateUserDto.fromJson(Map<String, dynamic> json) {
    return CreateUserDto(
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email};
  }
}
