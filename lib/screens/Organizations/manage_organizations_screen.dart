import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/screens/Organizations/organization_details_screen.dart';
import 'package:root2route/services/api.dart';

class ManageOrganizationsScreen extends StatefulWidget {
  const ManageOrganizationsScreen({super.key});

  @override
  State<ManageOrganizationsScreen> createState() => _ManageOrganizationsScreenState();
}

class _ManageOrganizationsScreenState extends State<ManageOrganizationsScreen> {
  final ApiService _api = ApiService();
  Future<Map<String, dynamic>>? _orgsFuture;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  void _loadOrgs() {
    setState(() {
      _orgsFuture = _api.getMyOrganizations();
    });
  }

  IconData _iconForType(int type) {
    switch (type) {
      case 0:
        return Icons.agriculture_outlined;
      case 1:
        return Icons.restaurant_outlined;
      case 2:
        return Icons.factory_outlined;
      case 3:
        return Icons.storefront_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  Color _colorForType(int type) {
    switch (type) {
      case 0:
        return const Color(0xFF2E7D32);
      case 1:
        return const Color(0xFFE65100);
      case 2:
        return const Color(0xFF1565C0);
      case 3:
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'إدارة الشركات',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _orgsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ في تحميل الشركات',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 16.sp),
                ),
              );
            }

            final result = snapshot.data;
            final List dataList = result?['data'] ?? [];
            final organizations = dataList
                .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
                .toList();

            if (organizations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد شركات مسجلة',
                      style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadOrgs();
                await _orgsFuture;
              },
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: organizations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final org = organizations[index];
                  final typeColor = _colorForType(org.type);

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconForType(org.type), color: typeColor, size: 24),
                      ),
                      title: Text(
                        org.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          org.typeName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrganizationDetailsScreen(
                              organization: org,
                              isMyOrganization: true,
                            ),
                          ),
                        ).then((_) {
                          // Refresh list when coming back just in case there were edits/deletions
                          _loadOrgs();
                        });
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
            ).then((_) {
               _loadOrgs();
            });
          },
        ),
      ),
    );
  }
}
