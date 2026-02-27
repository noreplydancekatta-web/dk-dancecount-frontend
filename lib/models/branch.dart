class Branch {
  final String id;
  final String name;
  final String address;
  final String pincode;
  final String area;
  final String mapLink;
  final String country;
  final String state;
  final String city;
  final String imageUrl;    // ✅ This must be exactly 'imageUrl'
  final String studioId;
  final String contactNo;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.pincode,
    required this.area,
    required this.mapLink,
    required this.country,
    required this.state,
    required this.city,
    required this.imageUrl,     // ✅ exactly same
    required this.studioId,
    required this.contactNo,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unnamed',
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      area: json['area'] ?? '',
      mapLink: json['mapLink'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      imageUrl: json['image'] ?? '',      // ✅ get from json['image']
      studioId: json['studioId'] ?? '',
      contactNo: json['contactNo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'pincode': pincode,
      'area': area,
      'mapLink': mapLink,
      'country': country,
      'state': state,
      'city': city,
      'image': imageUrl,      // ✅ save to json as 'image'
      'studioId': studioId,
      'contactNo': contactNo,
    };
  }
}
