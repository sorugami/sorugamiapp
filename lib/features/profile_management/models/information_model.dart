class InformationModel {
  InformationModel({required this.infoTitle, required this.infoDescription, required this.id});

  factory InformationModel.fromMap(Map<String, dynamic> map) {
    return InformationModel(
      id: (map['id'] ?? '') as String,
      infoTitle: (map['infoTitle'] ?? '') as String,
      infoDescription: (map['infoDescription'] ?? '') as String,
    );
  }
  String id;
  String infoTitle;
  String infoDescription;
}
