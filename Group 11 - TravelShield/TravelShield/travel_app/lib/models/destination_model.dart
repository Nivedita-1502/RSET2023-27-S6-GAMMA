class DestinationModel {
  final String name;
  final String district;

  const DestinationModel({
    required this.name,
    required this.district,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      name: json['name'] ?? '',
      district: json['district'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'district': district,
      };
}