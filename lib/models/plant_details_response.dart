import 'package:root2route/models/plant_step_model.dart';

class PlantDetailsResponse {
  final String plantId;
  final String plantInfoName;
  final String plantInfoScientificName;
  final String plantInfoIdealSoil;
  final List<PlantStepModel> steps;

  PlantDetailsResponse({
    required this.plantId,
    required this.plantInfoName,
    required this.plantInfoScientificName,
    required this.plantInfoIdealSoil,
    required this.steps,
  });

  factory PlantDetailsResponse.fromJson(Map<String, dynamic> json) {
    var list = json['steps'] as List? ?? [];
    List<PlantStepModel> stepsList =
        list.map((i) => PlantStepModel.fromJson(i)).toList();

    // Sort ascending by stepOrder
    stepsList.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return PlantDetailsResponse(
      plantId: json['plantId']?.toString() ?? '',
      plantInfoName: json['plantInfoName']?.toString() ?? '',
      plantInfoScientificName: json['plantInfoScientificName']?.toString() ?? '',
      plantInfoIdealSoil: json['plantInfoIdealSoil']?.toString() ?? '',
      steps: stepsList,
    );
  }
}
