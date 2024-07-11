import 'package:flutter/material.dart';

showSnackBar(BuildContext context, String message, bool isSuccess) {
  var snackBar = SnackBar(content: Text(message),
   backgroundColor: isSuccess ? Colors.green : Colors.red,
    behavior: SnackBarBehavior.floating,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}