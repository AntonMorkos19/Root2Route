import 'package:flutter/material.dart';

class DetailsProductModel {
  final String imagePath;
  final String title;
  final String location;
  final String price;
  final String quantity;
  final String description;
  final String badgeText;
  final String buttonText;
  final Color badgeColor;
  DetailsProductModel({
    required this.imagePath,
    required this.title,
    required this.location,
    required this.price,
    required this.quantity,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.buttonText,
  });
}
