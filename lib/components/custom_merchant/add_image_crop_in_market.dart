import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/core/theme/app_colors.dart';

class AddImageCropInMarket extends StatefulWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  const AddImageCropInMarket({
    super.key,
    required this.title, required this.icon, required this.subTitle,
  });

  @override
  State<AddImageCropInMarket> createState() => _AddImageCropInMarketState();
}

class _AddImageCropInMarketState extends State<AddImageCropInMarket> {
  File? imageFile;
  final ImagePicker picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  void showImageSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => imageFile = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showImageSource(context),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.Secondary,
            width: 1,
          ),
        ),
        child: imageFile == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                    (widget.icon),
                      size: 40,
                      color: AppColors.iconSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title, 
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
widget.subTitle,
                      style: TextStyle(
                        color: AppColors.textOnSecondary.withOpacity(.7),
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  imageFile!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}