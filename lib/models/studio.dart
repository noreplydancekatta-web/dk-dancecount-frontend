// 🔹 File: lib/models/studio.dart
class Studio {
  final String id;
  final String studioName;
  final String registeredAddress;
  final String contactEmail;
  final String contactNumber;
  final String gstNumber;
  final String panNumber;
  final String aadharFrontPhoto;
  final String aadharBackPhoto;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String studioIntroduction;
  final String? logoUrl;
  final String? studioWebsite;
  final String? studioFacebook;
  final String? studioYoutube;
  final String? studioInstagram;
  final String status;

  Studio({
    required this.id,
    required this.studioName,
    required this.registeredAddress,
    required this.contactEmail,
    required this.contactNumber,
    required this.gstNumber,
    required this.panNumber,
    required this.aadharFrontPhoto,
    required this.aadharBackPhoto,
    required this.bankAccountNumber,
    required this.bankIfscCode,
    required this.studioIntroduction,
    required this.logoUrl,
    required this.studioWebsite,
    required this.studioFacebook,
    required this.studioYoutube,
    required this.studioInstagram,
    required this.status,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['_id'],
      studioName: json['studioName'],
      registeredAddress: json['registeredAddress'],
      contactEmail: json['contactEmail'],
      contactNumber: json['contactNumber'],
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      aadharFrontPhoto: json['aadharFrontPhoto'],
      aadharBackPhoto: json['aadharBackPhoto'],
      bankAccountNumber: json['bankAccountNumber'],
      bankIfscCode: json['bankIfscCode'],
      studioIntroduction: json['studioIntroduction'],
      logoUrl: json['logoUrl'],
      studioWebsite: json['studioWebsite'],
      studioFacebook: json['studioFacebook'],
      studioYoutube: json['studioYoutube'],
      studioInstagram: json['studioInstagram'],
      status: json['status'],
    );
  }
}
