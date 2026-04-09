class PlantStepModel {
  final String id;
  final int stepOrder;
  final String title;
  final String instruction;

  PlantStepModel({
    required this.id,
    required this.stepOrder,
    required this.title,
    required this.instruction,
  });

  factory PlantStepModel.fromJson(Map<String, dynamic> json) {
    return PlantStepModel(
      id: json['id']?.toString() ?? '',
      stepOrder: json['stepOrder'] as int? ?? 0,
      title: json['title']?.toString() ?? 'No Title',
      instruction: json['instruction']?.toString() ?? 'No Instruction',
    );
  }
}
