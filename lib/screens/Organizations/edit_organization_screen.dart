import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/account_type_button.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/organization_model.dart';
import 'package:root2route/services/api.dart';

class EditOrganizationScreen extends StatefulWidget {
  final OrganizationModel organization;

  const EditOrganizationScreen({super.key, required this.organization});

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  AccountType? selectedType;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // ✅ دالة مساعدة لبناء رابط الصورة الكامل
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return 'https://root2route.runasp.net$imagePath';
  }

@override
void initState() {
  super.initState();
  
  // ✅ طباعة بيانات المنظمة للتأكد من الـ ID الصحيح
  print("============================================");
  print("🔍 EDIT SCREEN - Organization Data:");
  print("   ID: ${widget.organization.id}");
  print("   Name: ${widget.organization.name}");
  print("   Type: ${widget.organization.type}");
  print("   Email: ${widget.organization.contactEmail}");
  print("   Phone: ${widget.organization.contactPhone}");
  print("============================================");
  
  nameController.text = widget.organization.name;
  emailController.text = widget.organization.contactEmail ?? '';
  phoneController.text = widget.organization.contactPhone ?? '';
  addressController.text = widget.organization.address ?? '';
  descriptionController.text = widget.organization.description ?? '';
  selectedType = _getAccountTypeFromInt(widget.organization.type);
}
  AccountType _getAccountTypeFromInt(int type) {
    switch (type) {
      case 0:
        return AccountType.farmer;
      case 1:
        return AccountType.restaurant;
      case 2:
        return AccountType.factory;
      case 3:
        return AccountType.tradesman;
      default:
        return AccountType.farmer;
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

  // ✅ دالة لتنسيق رقم الهاتف (نفس اللي في ApiService)
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+2$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _updateOrganization() async {
  // التحقق من صحة النموذج
  if (!formKey.currentState!.validate()) return;

  // التحقق من اختيار نوع الحساب
  if (selectedType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select an account type'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // التحقق من اسم الشركة
  final orgName = nameController.text.trim();
  if (orgName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company name cannot be empty'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // عرض مؤشر التحميل
  setState(() => _isLoading = true);

  QuickAlert.show(
    context: context,
    type: QuickAlertType.loading,
    title: 'Loading',
    text: 'Updating your organization...',
    barrierDismissible: false,
  );

  // تنسيق رقم الهاتف
  final formattedPhone = _formatPhoneNumber(phoneController.text.trim());

  // ✅ طباعة الـ ID للتأكد
  print("🔍 EDIT SCREEN - Organization ID: ${widget.organization.id}");
  print("🔍 EDIT SCREEN - Organization Name: ${widget.organization.name}");

  try {
    // ✅ استخدام ID من القائمة للتجربة
    // لو عايز تجرب ب ID ثابت، استخدم السطر ده:
    // final testOrgId = "954489ef-f657-45f7-a10a-39a8127d76e7";
    
    final result = await _api.updateOrganization(
      organizationId: widget.organization.id, // استخدم ID المنظمة الحقيقية
      // organizationId: "954489ef-f657-45f7-a10a-39a8127d76e7", // للتجربة
      name: orgName,
      description: descriptionController.text.trim(),
      address: addressController.text.trim(),
      contactEmail: emailController.text.trim(),
      contactPhone: formattedPhone,
      type: _getOrganizationTypeValue(selectedType!),
      logo: _image,
    );

    if (!mounted) return;

    // إغلاق تنبيه التحميل
    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      // عرض رسالة نجاح
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success!',
        text: 'Organization updated successfully!',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.pop(context); // إغلاق التنبيه
          Navigator.pop(context, true); // الرجوع للشاشة السابقة مع نتيجة
        },
      );
    } else {
      // عرض رسالة فشل
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Failure',
        text: result['message'] ?? 'Failed to update organization',
        confirmBtnText: 'Try Again',
      );
    }
  } catch (e) {
    if (mounted) Navigator.pop(context);
    if (!mounted) return;
    
    // عرض رسالة خطأ غير متوقع
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Failure',
      text: 'An unexpected error occurred: $e',
      confirmBtnText: 'OK',
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تحديد مصدر الصورة (جديدة أو قديمة)
    ImageProvider? avatarImage;
    
    if (_image != null) {
      // لو اختار صورة جديدة
      avatarImage = FileImage(_image!);
    } else if (widget.organization.logoUrl != null &&
        widget.organization.logoUrl!.isNotEmpty) {
      // لو عنده صورة قديمة
      final imageUrl = _getFullImageUrl(widget.organization.logoUrl);
      if (imageUrl.isNotEmpty) {
        avatarImage = NetworkImage(imageUrl);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Organization',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Icon(Icons.business_outlined, size: 30, color: Colors.black),
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
                // ---- Banner ----
                Container(
                  height: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/Organizations.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: Container(
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 25,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Modify Your Organization",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Update your organization details quickly and professionally.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ---- Logo Picker ----
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
                              color: Colors.black.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 30,
                                    color: AppColors.OrganizationColor,
                                  )
                                : null,
                          ),
                        ),
                        const Positioned(
                          bottom: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black,
                            child: Icon(
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

                // ---- Form Fields ----
                CustomTextFormField(
                  icon: Icons.business_outlined,
                  color: Colors.black,
                  cursorColor: AppColors.OrganizationColor,
                  borderColor: AppColors.OrganizationColor,
                  label: 'Company Name',
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.email,
                  color: Colors.black,
                  cursorColor: AppColors.OrganizationColor,
                  borderColor: AppColors.OrganizationColor,
                  label: 'Email',
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.phone_outlined,
                  color: Colors.black,
                  cursorColor: AppColors.OrganizationColor,
                  borderColor: AppColors.OrganizationColor,
                  label: 'Phone Number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone';
                    }
                    // ✅ قبول أرقام بصيغ مختلفة (محلية أو دولية)
                    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
                    if (!RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(cleaned)) {
                      return 'Enter a valid phone number (e.g., 01234567890 or +201234567890)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  icon: Icons.location_on_outlined,
                  cursorColor: AppColors.OrganizationColor,
                  borderColor: AppColors.OrganizationColor,
                  label: 'Address',
                  controller: addressController,
                  color: Colors.black,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ---- Account Type ----
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: AccountTypeButton(
                        text: 'Farmer',
                        icon: Icons.agriculture_outlined,
                        selected: selectedType == AccountType.farmer,
                        onTap: () => setState(() {
                          selectedType = AccountType.farmer;
                        }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'Restaurant',
                        icon: Icons.fastfood,
                        selected: selectedType == AccountType.restaurant,
                        onTap: () => setState(() {
                          selectedType = AccountType.restaurant;
                        }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'Factory',
                        icon: Icons.factory_outlined,
                        selected: selectedType == AccountType.factory,
                        onTap: () => setState(() {
                          selectedType = AccountType.factory;
                        }),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: AccountTypeButton(
                        text: 'Tradesman',
                        icon: Icons.storefront_outlined,
                        selected: selectedType == AccountType.tradesman,
                        onTap: () => setState(() {
                          selectedType = AccountType.tradesman;
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ---- Description ----
                CustomTextFormField(
                  icon: Icons.description_outlined,
                  cursorColor: AppColors.OrganizationColor,
                  borderColor: AppColors.OrganizationColor,
                  label: 'Description',
                  controller: descriptionController,
                  color: Colors.black,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ---- Update Button ----
                CustomButton(
                  text: _isLoading ? 'Updating...' : 'Update Company',
                  color: AppColors.OrganizationColor,
                  onPressed: _isLoading ? () {} : _updateOrganization,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}