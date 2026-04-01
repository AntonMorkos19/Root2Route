import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:root2route/components/Organizations/organization_card.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/services/api.dart';

class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  final ApiService _api = ApiService();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      // بنادي على API اللي بيجيب كل الشركات فقط
      _future = _api.getOrganizations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'All Organizations',
          style: TextStyle(
            color: Color(0xff2D3748),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.OrganizationColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final result = snapshot.data;
            if (result == null || result['success'] != true) {
              return _buildErrorState(
                result?['message'] ?? 'Failed to load organizations',
              );
            }

            final List dataList = result['data'] ?? [];
            if (dataList.isEmpty) {
              return _buildEmptyState();
            }

            final organizations =
                dataList
                    .map(
                      (json) => OrganizationModel.fromJson(
                        json is Map<String, dynamic>
                            ? json
                            : <String, dynamic>{},
                      ),
                    )
                    .toList();

            return RefreshIndicator(
              color: AppColors.OrganizationColor,
              onRefresh: () async => _loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  return OrganizationCard(
                    organization: organizations[index],
                    onDeleted: () => _loadData(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Organizations Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          TextButton(onPressed: _loadData, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
