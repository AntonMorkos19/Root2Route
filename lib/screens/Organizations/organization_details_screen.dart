import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/Organizations/edit_organization_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';

class OrganizationDetailsScreen extends StatefulWidget {
  final OrganizationModel organization;

  const OrganizationDetailsScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends State<OrganizationDetailsScreen> {
  final ApiService _api = ApiService();
  OrganizationStatisticsModel? _stats;
  bool _statsLoading = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    final result = await _api.getOrganizationStatistics(widget.organization.id);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _stats = OrganizationStatisticsModel.fromJson(
          result['data'] is Map<String, dynamic>
              ? result['data']
              : <String, dynamic>{},
        );
        _statsLoading = false;
      });
    } else {
      setState(() {
        _statsError = result['message'] ?? 'Failed to load statistics';
        _statsLoading = false;
      });
    }
  }

  IconData _typeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.agriculture_outlined;
      case 1:
        return Icons.fastfood;
      case 2:
        return Icons.factory_outlined;
      case 3:
        return Icons.storefront_outlined;
      default:
        return Icons.business;
    }
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return 'https://root2route.runasp.net$imagePath';
  }

  Future<void> _deleteOrganization() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'Delete Organization?',
      text: 'This action cannot be undone.',
      confirmBtnText: 'Yes, Delete',
      cancelBtnText: 'Cancel',
      confirmBtnColor: Colors.red,
      showCancelBtn: true,
      onConfirmBtnTap: () async {
        Navigator.pop(context);

        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Deleting',
          text: 'Please wait...',
          barrierDismissible: false,
        );

        final result = await _api.deleteOrganization(widget.organization.id);

        if (mounted) Navigator.pop(context);

        if (mounted) {
          if (result['success'] == true) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Deleted!',
              text: 'Organization deleted successfully.',
              confirmBtnText: 'OK',
              onConfirmBtnTap: () {
                Navigator.pop(context); // close alert
                Navigator.pop(context); // go back to list
              },
            );
          } else {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: result['message'] ?? 'Failed to delete',
              confirmBtnText: 'OK',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;
    final String imageUrl = _getFullImageUrl(org.logoUrl);
    final bool hasImage = imageUrl.isNotEmpty;

    // Show the ⋮ menu only if this org belongs to the logged-in user.
    final bool isOwner = StorageService().organizationId == org.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Organization Details',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color ?? Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions:
            isOwner
                ? [
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).iconTheme.color ?? Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      EditOrganizationScreen(organization: org),
                            ),
                          ).then((_) => setState(() {}));
                          break;

                        case 'delete':
                          _deleteOrganization();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, color: Colors.orange),
                              title: Text('Edit Organization'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete Organization'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                  ),
                ]
                : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        image:
                            hasImage
                                ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    debugPrint(
                                      ' Error loading logo: $exception',
                                    );
                                  },
                                )
                                : null,
                      ),
                      child:
                          !hasImage
                              ? Center(
                                child: Text(
                                  org.name.length >= 2
                                      ? org.name.substring(0, 2).toUpperCase()
                                      : org.name.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26.sp,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      org.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).textTheme.titleLarge?.color ??
                            const Color(0xff1a1a1a),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _typeIcon(org.type),
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          org.typeName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SectionTitle('Statistics'),
              const SizedBox(height: 10),
              StatisticsGrid(),

              const SizedBox(height: 20),

              SectionTitle('Details'),
              const SizedBox(height: 10),

              if (org.description != null && org.description!.isNotEmpty)
                InfoCard(
                  Icons.description_outlined,
                  'Description',
                  org.description!,
                ),
              if (org.address != null && org.address!.isNotEmpty)
                InfoCard(Icons.location_on_outlined, 'Address', org.address!),
              if (org.contactEmail != null && org.contactEmail!.isNotEmpty)
                InfoCard(Icons.email_outlined, 'Email', org.contactEmail!),
              if (org.contactPhone != null && org.contactPhone!.isNotEmpty)
                InfoCard(Icons.phone_outlined, 'Phone', org.contactPhone!),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget SectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color:
              Theme.of(context).textTheme.titleLarge?.color ??
              const Color(0xff333333),
        ),
      ),
    );
  }

  Widget StatisticsGrid() {
    if (_statsLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_statsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(
              _statsError!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    final stats = _stats!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          Icons.people_outlined,
          'Members',
          stats.totalMembers,
          Colors.blue,
        ),
        StatCard(
          Icons.inventory_2_outlined,
          'Products',
          stats.totalProducts,
          Colors.green,
        ),
      ],
    );
  }

  Widget StatCard(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget InfoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        const Color(0xff333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
