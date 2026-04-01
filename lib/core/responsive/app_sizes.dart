import 'package:flutter/material.dart';

class AppSizes {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;
  static double paddingSize(BuildContext context) => width(context) * 0.03;
  static double marginSize(BuildContext context) => width(context) * 0.03;
}
