import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/factory/factory_home_screen.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/screens/restaurant/restaurant_home_screen.dart';
import 'package:root2route/screens/tradesman/tradesman_home_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:quickalert/quickalert.dart';

/// Shows a bottom-sheet listing every organization owned by the user.
/// The currently-active org is highlighted with a checkmark.
/// Tapping a different org switches context and navigates to its home screen.
void showSwitchOrganizationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SwitchOrganizationSheet(parentContext: context),
  );
}

// ─── Icon helper ────────────────────────────────────────────────────────────

IconData _iconForType(int type) {
  switch (type) {
    case 0:
      return Icons.agriculture_outlined;  // مزارع
    case 1:
      return Icons.restaurant_outlined;  // مطعم
    case 2:
      return Icons.factory_outlined;     // مصنع
    case 3:
      return Icons.storefront_outlined;  // تاجر
    default:
      return Icons.business_outlined;
  }
}

Color _colorForType(int type) {
  switch (type) {
    case 0:
      return const Color(0xFF2E7D32); // green — farmer
    case 1:
      return const Color(0xFFE65100); // orange — restaurant
    case 2:
      return const Color(0xFF1565C0); // blue — factory
    case 3:
      return const Color(0xFF6A1B9A); // purple — tradesman
    default:
      return AppColors.primary;
  }
}

Widget _homeScreenForType(int type, {Key? key}) {
  switch (type) {
    case 0:
      return FarmerHomeScreen(key: key);
    case 1:
      return RestaurantHomeScreen(key: key);
    case 2:
      return FactoryHomeScreen(key: key);
    case 3:
      return TradesmanHomeScreen(key: key);
    default:
      return FarmerHomeScreen(key: key);
  }
}

// ─── Sheet widget ────────────────────────────────────────────────────────────

class _SwitchOrganizationSheet extends StatefulWidget {
  final BuildContext parentContext;
  const _SwitchOrganizationSheet({required this.parentContext});

  @override
  State<_SwitchOrganizationSheet> createState() =>
      _SwitchOrganizationSheetState();
}

class _SwitchOrganizationSheetState extends State<_SwitchOrganizationSheet> {
  late Future<List<OrganizationModel>> _future;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchOrgs();
  }

  Future<List<OrganizationModel>> _fetchOrgs() async {
    final result = await ApiService().getMyOrganizations();
    if (result['success'] != true) return [];
    final List raw = result['data'] ?? [];
    return raw
        .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _switchTo(OrganizationModel org) async {

    if (_isSwitching) return;
    setState(() => _isSwitching = true);

    // 1. Persist the new active org
    await StorageService().saveOrganizationDetails(
      orgId: org.id,
      orgType: org.type,
    );

    // 2. Clear cart state
    if (widget.parentContext.mounted) {
      try {
        widget.parentContext.read<CartCubit>().clearCart();
      } catch (_) {
        // CartCubit might not be available in every context — safe to ignore
      }
    }

    if (!mounted) return;

    // 3. Close the sheet, then navigate (avoids context issues)
    Navigator.of(context).pop();

    if (widget.parentContext.mounted) {
      Navigator.of(widget.parentContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _homeScreenForType(org.type, key: UniqueKey())),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrgId = StorageService().organizationId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تبديل الشركة',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      'اختر الشركة النشطة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Organization list ─────────────────────────────────────────
            FutureBuilder<List<OrganizationModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final orgs = (snapshot.data ?? []).where((org) => org.status == 1).toList();

                if (orgs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'لا توجد شركات مسجلة',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orgs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final org = orgs[i];
                    final isActive = org.id == activeOrgId;
                    final typeColor = _colorForType(org.type);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForType(org.type),
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          org.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          org.typeName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: isActive
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 24,
                              )
                            : _isSwitching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade400,
                                    size: 24,
                                  ),
                        onTap: isActive ? null : () => _switchTo(org),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
