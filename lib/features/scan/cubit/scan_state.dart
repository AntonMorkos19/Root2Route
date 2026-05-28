import 'package:root2route/features/scan/models/plant_analysis_response_model.dart';

/// Base state for [ScanCubit].
abstract class ScanState {
  const ScanState();
}

/// Idle – no scan has been started yet.
class ScanInitial extends ScanState {
  const ScanInitial();
}

/// Image has been picked and the request is in-flight.
class ScanLoading extends ScanState {
  const ScanLoading();
}

/// The AI analysis completed successfully.
class ScanSuccess extends ScanState {
  final PlantAnalysisResponseModel result;
  const ScanSuccess(this.result);
}

/// Something went wrong (network, server, or model error).
class ScanFailure extends ScanState {
  final String error;
  const ScanFailure(this.error);
}
