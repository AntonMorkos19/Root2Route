class UserModel {
  final String fullName;
  final String address;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;

  UserModel({
    required this.fullName,
    required this.address,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['fullName'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirmPassword'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName,
      "address": address,
      "email": email,
      "password": password,
      "confirmPassword": confirmPassword,
      "phoneNumber": phoneNumber,
    };
  }
}
