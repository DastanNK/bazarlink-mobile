// lib/features/auth/domain/entities/consumer_registration.dart

import '../../../../core/localization/app_language.dart';

class ConsumerSignUpData {
  final String email;
  final String password;
  final String fullName;
  final AppLanguage language;
  final String businessName;
  final String country;
  final String? phone;
  final String? city;
  final String? address;
  final String? businessType;
  final String? description;

  const ConsumerSignUpData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.language,
    required this.businessName,
    required this.country,
    this.phone,
    this.city,
    this.address,
    this.businessType,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'language': language.code,
      'consumer': {
        'business_name': businessName,
        'country': country,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (businessType != null && businessType!.isNotEmpty)
          'business_type': businessType,
        if (description != null && description!.isNotEmpty)
          'description': description,
      },
    };
  }
}

