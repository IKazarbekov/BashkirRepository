class ApiEndpoints {
  static const String baseUrl = 'http://10.136.202.1:8000';

  static const String register = '$baseUrl/user/reg';
  static const String login = '$baseUrl/user/log';
  static const String currentUser = '$baseUrl/users/me';
  static const String getAllUsers = '$baseUrl/user/getall';
}
