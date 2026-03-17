import 'capabilities.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.capabilities,
    required this.user,
    required this.groups,
  });

  final String token;
  final Capabilities capabilities;
  final String? user;
  final List<String> groups;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? json['auth_token'] ?? '').toString();
    final user = (json['username'] ?? json['user']?['username'])?.toString();
    final groupsRaw = json['groups'];
    final groups = groupsRaw is List
        ? groupsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return LoginResponse(
      token: token,
      capabilities: Capabilities.fromDynamic(json['capabilities']),
      user: user,
      groups: groups,
    );
  }
}
