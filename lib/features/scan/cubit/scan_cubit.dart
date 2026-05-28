import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/scan/cubit/scan_state.dart';
import 'package:root2route/features/scan/repository/scan_repository.dart';

/// Manages the plant-disease AI analysis lifecycle.
///
/// Usage:
/// ```dart
/// context.read<ScanCubit>().uploadAndAnalyzeImage(imageFile);
/// ```
class ScanCubit extends Cubit<ScanState> {
  final ScanRepository _repository;

  ScanCubit({ScanRepository? repository})
    : _repository = repository ?? ScanRepository(),
      super(const ScanInitial());

  // ── Public API ────────────────────────────────────────────────

  /// Picks up [image], uploads it to the AI endpoint, and emits either
  /// [ScanSuccess] or [ScanFailure].
  Future<void> uploadAndAnalyzeImage(File image) async {
    _emitSafe(const ScanLoading());

    try {
      final result = await _repository.analyzePlantImage(image);
      _emitSafe(ScanSuccess(result));
    } on ScanException catch (e) {
      _emitSafe(ScanFailure(e.message));
    } catch (e) {
      _emitSafe(ScanFailure('Unexpected error: $e'));
    }
  }

  /// Resets the cubit back to [ScanInitial] (e.g. "Scan Again" button).
  void reset() => _emitSafe(const ScanInitial());

  // ── Helpers ───────────────────────────────────────────────────

  void _emitSafe(ScanState state) {
    if (!isClosed) emit(state);
  }
}
