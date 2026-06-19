import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/services/api.dart';

abstract class UpdateOrganizationState {}

class UpdateOrganizationInitial extends UpdateOrganizationState {}

class UpdateOrganizationLoading extends UpdateOrganizationState {}

class UpdateOrganizationSuccess extends UpdateOrganizationState {}

class UpdateOrganizationError extends UpdateOrganizationState {
  final String message;
  UpdateOrganizationError(this.message);
}

class UpdateOrganizationCubit extends Cubit<UpdateOrganizationState> {
  final ApiService _apiService;

  UpdateOrganizationCubit(this._apiService) : super(UpdateOrganizationInitial());

  Future<void> updateOrganization({
    required String organizationId,
    required String name,
    required int type,
    String? description,
    String? address,
    String? contactEmail,
    String? contactPhone,
    File? logo,
  }) async {
    emit(UpdateOrganizationLoading());
    try {
      final response = await _apiService.updateOrganization(
        organizationId: organizationId,
        name: name,
        type: type,
        description: description,
        address: address,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        logo: logo,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        emit(UpdateOrganizationSuccess());
      } else {
        emit(UpdateOrganizationError('Failed to update organization.'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        String errorMessage = 'Bad Request';
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          if (data['errors'] != null) {
            final errors = data['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError[0].toString();
              } else {
                errorMessage = firstError.toString();
              }
            } else if (errors is List && errors.isNotEmpty) {
              errorMessage = errors[0].toString();
            }
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          } else if (data['title'] != null) {
            errorMessage = data['title'];
          }
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
        emit(UpdateOrganizationError(errorMessage));
      } else {
        emit(UpdateOrganizationError(e.response?.statusMessage ?? e.message ?? 'An unexpected error occurred.'));
      }
    } catch (e) {
      emit(UpdateOrganizationError('An unexpected error occurred: $e'));
    }
  }
}
