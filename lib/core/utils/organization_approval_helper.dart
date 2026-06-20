import 'package:flutter/material.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/screens/restaurant/restaurant_home_screen.dart';
import 'package:root2route/screens/factory/factory_home_screen.dart';
import 'package:root2route/screens/tradesman/tradesman_home_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';

/// Utility class for checking organization approval status
/// and routing users to their correct dashboard.
class OrganizationApprovalHelper {
  OrganizationApprovalHelper._(); // prevent instantiation

  /// Silently calls the refresh-token API to check if the organization
  /// has been approved. If approved, updates local storage and navigates
  /// to the appropriate dashboard.
  ///
  /// Returns `true` if the user was routed to a dashboard, `false` otherwise.
  static Future<bool> checkOrganizationApprovalAndRoute(
    BuildContext context,
  ) async {
    final storage = StorageService();

    // Only relevant for users with a pending organization
    if (!storage.hasOrganization || storage.organizationStatus != 0) {
      return false;
    }

    try {
      // Silently refresh the token — the server embeds updated claims
      final refreshed = await ApiService().refreshAuthToken();

      if (!refreshed) {
        // Token refresh failed — keep them in guest, show feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يزال الطلب قيد المراجعة'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }

      // Re-read storage — refreshAuthToken may have updated org data
      final updatedStatus = storage.organizationStatus;

      if (updatedStatus == 1) {
        // ✅ Approved — route to the correct dashboard
        final orgType = storage.organizationType ?? 0;
        final targetScreen = _getHomeScreenForType(orgType);

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
            (route) => false,
          );
        }
        return true;
      } else {
        // Still pending
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يزال الطلب قيد المراجعة'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Organization approval check failed: $e');
      return false;
    }
  }

  /// Maps an organization type to its corresponding home screen.
  static Widget _getHomeScreenForType(int type) {
    switch (type) {
      case 0:
        return const FarmerHomeScreen();
      case 1:
        return const RestaurantHomeScreen();
      case 2:
        return const FactoryHomeScreen();
      case 3:
        return const TradesmanHomeScreen();
      default:
        return const FarmerHomeScreen();
    }
  }
}
