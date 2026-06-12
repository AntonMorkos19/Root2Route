import 'package:quickalert/quickalert.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/account_type_button.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/factory/factory_home_screen.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/screens/tradesman/tradesman_home_screen.dart';
import 'package:root2route/screens/restaurant/restaurant_home_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';
import 'package:root2route/core/utils/app_validators.dart';

class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  AccountType? selectedType;

  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // Compliance file state
  File? _complianceFile;
  String? _complianceFileName;
  bool _complianceError = false;

  Future<void> _pickImage() async {
    if (_isLoading) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickComplianceFile() async {
    if (_isLoading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _complianceFile = File(result.files.single.path!);
        _complianceFileName = result.files.single.name;
        _complianceError = false;
      });
    }
  }

  int _getOrganizationTypeValue(AccountType type) {
    switch (type) {
      case AccountType.farmer:
        return 0;
      case AccountType.restaurant:
        return 1;
      case AccountType.factory:
        return 2;
      case AccountType.tradesman:
        return 3;
    }
  }

  Widget _getTargetScreen(AccountType type) {
    switch (type) {
      case AccountType.farmer:
        return const FarmerHomeScreen();
      case AccountType.restaurant:
        return const RestaurantHomeScreen();
      case AccountType.factory:
        return const FactoryHomeScreen();
      case AccountType.tradesman:
        return const TradesmanHomeScreen();
    }
  }

  Future<void> _createOrganization() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد نوع الحساب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_complianceFile == null) {
      setState(() => _complianceError = true);
      return;
    }

    setState(() => _isLoading = true);
    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
      context: context,
      type: QuickAlertType.loading,
      title: 'جاري التحميل',
      text: 'جاري إنشاء شركتك...',
      barrierDismissible: false,
    );

    try {
      final result = await _api.createOrganization(
        name: nameController.text.trim(),
        type: _getOrganizationTypeValue(selectedType!),
        complianceFile: _complianceFile!,
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        contactEmail: emailController.text.trim(),
        contactPhone: phoneController.text.trim(),
        logo: _image,
      );

      if (mounted) Navigator.pop(context); // close loading dialog

      if (!mounted) return;

      if (result['success']) {
        final orgId =
            result['data']?['id'] ??
            result['data']?['organizationId'] ??
            result['data']?['OrganizationId'] ??
            '';

        // Atomically persist the new active org
        await StorageService().saveOrganizationDetails(
          orgId: orgId.toString(),
          orgType: _getOrganizationTypeValue(selectedType!),
        );

        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم إنشاء الشركة بنجاح!');
        // pushAndRemoveUntil so the new home screen is the new root
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => _getTargetScreen(selectedType!)),
          (route) => false,
        );
      } else {
        QuickAlert.show(cancelBtnText: 'إلغاء', 
          context: context,
          type: QuickAlertType.error,
          title: ' فشل',
          text: result['message'] ?? 'فشل إنشاء الشركة',
          barrierDismissible: false,
          confirmBtnText: 'المحاولة مرة أخرى',
        );
      }
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(cancelBtnText: 'إلغاء', 
        context: context,
        type: QuickAlertType.error,
        title: 'فشل',
        text: 'حدث خطأ غير متوقع: $e',
        barrierDismissible: false,
        confirmBtnText: 'موافق',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'إنشاء شركة',
            style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Icon(
              Icons.business_outlined,
              size: 30,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            backgroundImage:
                                _imageBytes != null
                                    ? MemoryImage(_imageBytes!)
                                    : null,
                            child:
                                _image == null
                                    ? Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 30,
                                      color: AppColors.primary,
                                    )
                                    : null,
                          ),
                        ),

                        // Edit icon
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black,
                            child: const Icon(
                              Icons.edit,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  icon: Icons.business_outlined,
                  label: 'اسم الشركة',
                  controller: nameController,
                  validator: (val) => AppValidators.validateRequired(val, 'اسم الشركة'),
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.email,
                  label: 'البريد الإلكتروني',
                  textDirection: TextDirection.ltr,
                  controller: emailController,
                  validator: AppValidators.validateEmail,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  textDirection: TextDirection.ltr,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.location_on_outlined,
                  label: 'العنوان',
                  controller: addressController,
                  validator: (val) => AppValidators.validateRequired(val, 'العنوان'),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'نوع الحساب',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleSmall?.color,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: AccountTypeButton(
                        text: 'مزارع',
                        icon: Icons.agriculture_outlined,
                        selected: selectedType == AccountType.farmer,
                        onTap:
                            () => setState(() {
                              selectedType = AccountType.farmer;
                            }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'مطعم',
                        icon: Icons.fastfood,

                        selected: selectedType == AccountType.restaurant,
                        onTap:
                            () => setState(() {
                              selectedType = AccountType.restaurant;
                            }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'مصنع',

                        icon: Icons.factory_outlined,
                        selected: selectedType == AccountType.factory,
                        onTap:
                            () => setState(() {
                              selectedType = AccountType.factory;
                            }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'تاجر',
                        icon: Icons.storefront_outlined,

                        selected: selectedType == AccountType.tradesman,
                        onTap:
                            () => setState(() {
                              selectedType = AccountType.tradesman;
                            }),
                      ),
                    ),
                    const SizedBox(width: 11),
                  ],
                ),

                const SizedBox(height: 20),

                CustomTextFormField(
                  icon: Icons.description_outlined,
                  label: 'الوصف',
                  controller: descriptionController,
                  maxLines: 3,
                  validator: (val) => AppValidators.validateRequired(val, 'الوصف'),
                ),

                const SizedBox(height: 20),

                // ── Compliance File Picker ──────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ملف التوثيق *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleSmall?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickComplianceFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _complianceFile != null
                          ? AppColors.primary.withOpacity(0.06)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _complianceError
                            ? Colors.red
                            : _complianceFile != null
                                ? AppColors.primary.withOpacity(0.4)
                                : Colors.grey.shade300,
                        width: _complianceError ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _complianceFile != null
                              ? Icons.check_circle
                              : Icons.upload_file_outlined,
                          color: _complianceFile != null
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _complianceFileName ?? 'إرفاق ملف التوثيق (PDF, DOC, صورة)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _complianceFile != null
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                  : Colors.grey.shade500,
                              fontWeight: _complianceFile != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_complianceFile != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _complianceFile = null;
                                _complianceFileName = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_complianceError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 4),
                    child: Text(
                      'يجب إرفاق ملف توثيق الشركة',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                // ────────────────────────────────────────────────────

                const SizedBox(height: 30),

                CustomButton(
                  color: AppColors.primary,
                  text: 'إنشاء الشركة',
                  onPressed: () {
                    _createOrganization();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
