import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/components/Organizations/organization_card.dart';
import 'package:root2route/components/Organizations/add_organization_card.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/Organizations/organizations_list_screen.dart';
import 'package:root2route/screens/account_screen.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/features/reviews/ui/organization_reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black),
            onSelected: (value) {
              if (value == 'all_orgs') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrganizationsListScreen(),
                  ),
                );
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'all_orgs',
                    child: ListTile(
                      leading: Icon(
                        Icons.business_outlined,
                        color: Color(0xff0F4C5C),
                      ),
                      title: Text('All Organizations'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppColors.OrganizationColor,
                    ),
                    title: const Text(
                      'Account Settings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.OrganizationColor,
                    ),
                    title: const Text(
                      'My Addresses',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.star_rate, color: Colors.amber),
                    title: const Text(
                      'Customer Reviews',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final orgId = StorageService().organizationId;
                      if (orgId == null || orgId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No active organization found to view reviews.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OrganizationReviewsScreen(
                                organizationId: orgId,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'My Organizations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: const Color(0xff2D3748),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _orgsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.OrganizationColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading organizations',
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    );
                  }

                  final result = snapshot.data;
                  final List dataList = result?['data'] ?? [];

                  final organizations =
                      dataList
                          .map(
                            (json) => OrganizationModel.fromJson(
                              json as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                  return Column(
                    children: [
                      const AddOrganizationCard(),
                      ...organizations.map(
                        (org) => OrganizationCard(
                          organization: org,
                          onDeleted: () => _loadOrgs(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
