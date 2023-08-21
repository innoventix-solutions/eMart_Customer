import 'package:emartconsumer/model/User.dart';

class AddressModel {
  String city;

  String country;

  String email;

  String line1;

  String line2;

  UserLocation location;

  String name;

  String postalCode;

  AddressModel({this.city = '', this.country = '', this.email = '', this.line1 = '', this.line2 = '', location, this.name = '', this.postalCode = ''}) : location = location ?? UserLocation();

  factory AddressModel.fromJson(Map<String, dynamic> parsedJson) {
    return AddressModel(
      city: parsedJson['city'] ?? '',
      country: parsedJson['country'] ?? '',
      email: parsedJson['email'] ?? '',
      line1: parsedJson['line1'] ?? '',
      line2: parsedJson['line2'] ?? '',
      location: parsedJson.containsKey('location') ? UserLocation.fromJson(parsedJson['location']) : UserLocation(),
      name: parsedJson['name'] ?? '',
      postalCode: parsedJson['postalCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'email': email,
      'line1': line1,
      'line2': line2,
      'location': location.toJson(),
      'name': name,
      'postalCode': postalCode,
    };
  }
}
