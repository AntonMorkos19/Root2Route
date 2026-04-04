import 'package:flutter/material.dart';
import 'package:root2route/components/Organizations/organization_card.dart';
import 'package:root2route/components/Organizations/add_organization_card.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/Organizations/organizations_list_screen.dart';
import 'package:root2route/screens/account_screen.dart';
import 'package:root2route/services/api.dart';

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
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.OrganizationColor,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Anton',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'antonmorkos6@gmail.com',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: CustomButton(
                          text: 'Edit Profile',
                          color: AppColors.OrganizationColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    Text(
                      'My Organizations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xff2D3748),
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
