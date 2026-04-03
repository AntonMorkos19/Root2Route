import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/screens/Organizations/add_member_screen.dart';
import 'package:root2route/screens/Organizations/edit_organization_screen.dart';
import 'package:root2route/services/api.dart';

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

  // دالة مساعدة لبناء رابط الصورة الكامل
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

  void _showChangeOwnerDialog() {
    final ownerIdController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.swap_horiz, color: AppColors.OrganizationColor),
                SizedBox(width: 8),
                Text(
                  'Transfer Ownership',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Form(
              key: dialogFormKey,
              child: CustomTextFormField(
                icon: Icons.person_outline,
                label: 'New Owner ID (GUID)',
                controller: ownerIdController,
                color: Colors.black,
                cursorColor: AppColors.OrganizationColor,
                borderColor: AppColors.OrganizationColor,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the new owner ID';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.OrganizationColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (!dialogFormKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  _changeOwner(ownerIdController.text.trim());
                },
                child: const Text(
                  'Transfer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _changeOwner(String newOwnerId) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'Transfer Ownership?',
      text:
          'You will lose ownership of this organization. This cannot be easily reversed.',
      confirmBtnText: 'Yes, Transfer',
      cancelBtnText: 'Cancel',
      confirmBtnColor: Colors.red,
      showCancelBtn: true,
      onConfirmBtnTap: () async {
        Navigator.pop(context);

        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Transferring',
          text: 'Please wait...',
          barrierDismissible: false,
        );

        final result = await _api.changeOrganizationOwner(
          organizationId: widget.organization.id,
          newOwnerId: newOwnerId,
        );

        if (mounted) Navigator.pop(context);

        if (mounted) {
          if (result['success'] == true) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Transferred!',
              text: 'Ownership transferred successfully.',
              confirmBtnText: 'OK',
              onConfirmBtnTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            );
          } else {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: result['message'] ?? 'Failed to transfer ownership',
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

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Organization Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // القائمة العلوية
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditOrganizationScreen(organization: org),
                    ),
                  ).then((_) => setState(() {}));
                  break;
                case 'add_member':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMemberScreen(),
                    ),
                  );
                  break;
                case 'owner':
                  _showChangeOwnerDialog();
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
                    value: 'add_member',
                    child: ListTile(
                      leading: Icon(Icons.person_add_alt_1, color: Colors.blue),
                      title: Text('Add Member'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'owner',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Colors.purple),
                      title: Text('Transfer Ownership'),
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
        ],
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
                  color: Colors.white,
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
                        color: AppColors.OrganizationColor,
                        borderRadius: BorderRadius.circular(20),
                        image:
                            hasImage
                                ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    debugPrint(
                                      '❌ Error loading logo: $exception',
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1a1a1a),
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
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---- Statistics Section ----
              _buildSectionTitle('Statistics'),
              const SizedBox(height: 10),
              _buildStatisticsGrid(),

              const SizedBox(height: 20),

              // ---- Info Cards ----
              _buildSectionTitle('Details'),
              const SizedBox(height: 10),

              if (org.description != null && org.description!.isNotEmpty)
                _buildInfoCard(
                  Icons.description_outlined,
                  'Description',
                  org.description!,
                ),
              if (org.address != null && org.address!.isNotEmpty)
                _buildInfoCard(
                  Icons.location_on_outlined,
                  'Address',
                  org.address!,
                ),
              if (org.contactEmail != null && org.contactEmail!.isNotEmpty)
                _buildInfoCard(
                  Icons.email_outlined,
                  'Email',
                  org.contactEmail!,
                ),
              if (org.contactPhone != null && org.contactPhone!.isNotEmpty)
                _buildInfoCard(
                  Icons.phone_outlined,
                  'Phone',
                  org.contactPhone!,
                ),

              const SizedBox(
                height: 40,
              ), // مساحة فاضية في آخر الشاشة عشان شكلها يبقى أنيق
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xff333333),
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    if (_statsLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
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
            color: AppColors.OrganizationColor,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(
              _statsError!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.OrganizationColor,
              ),
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
        _buildStatCard(
          Icons.people_outlined,
          'Members',
          stats.totalMembers,
          Colors.blue,
        ),
        _buildStatCard(
          Icons.inventory_2_outlined,
          'Products',
          stats.totalProducts,
          Colors.green,
        ),
        _buildStatCard(
          Icons.shopping_bag_outlined,
          'Orders',
          stats.totalOrders,
          Colors.orange,
        ),
        _buildStatCard(
          Icons.grass_outlined,
          'Farms',
          stats.totalFarms,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  fontSize: 22,
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
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: AppColors.OrganizationColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.OrganizationColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff333333),
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
