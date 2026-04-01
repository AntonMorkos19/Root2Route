import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';

class RequestProduct extends StatefulWidget {
  const RequestProduct({super.key});

  @override
  State<RequestProduct> createState() => _RequestProductState();
}

class _RequestProductState extends State<RequestProduct> {
  final cropNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? selectedCropType;
  final List<String> cropTypes = ['Vegetables', 'Fruits', 'Grains', 'Herbs'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: AppSizes.width(context),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: Icon(
                          Icons.spa,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Request Crop",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        "Send a request for a crop you need",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(239, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Crop Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                CustomTextFormField(
                  color: Colors.black,
                  icon: Icons.grass,
                  label: 'Example: cucumber, tomato',
                  controller: cropNameController,

                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter crop name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                const Text(
                  'Crop Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCropType,
                  decoration: InputDecoration(
                    hintText: 'Select crop type',
                    prefixIcon: Icon(Icons.spa, color: AppColors.iconSecondary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),

                      borderRadius: BorderRadius.circular(12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items:
                      cropTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCropType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select crop type';
                    return null;
                  },
                ),

                const SizedBox(height: 17),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Send  ',
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;

                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: 'The request has been sent successfully',
                            showConfirmBtn: false,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),

                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        color: Colors.grey.shade500,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
