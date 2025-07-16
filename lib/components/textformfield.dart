import 'package:flutter/material.dart';

class CostumeFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController myController;
  final bool obsecuretext;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const CostumeFormField({
    super.key,
    required this.hintText,
    required this.myController,
    this.obsecuretext = false,
    required this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        validator: validator,
        controller: myController,
        obscureText: obsecuretext,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          filled: true,
          fillColor: Colors.transparent,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 28, 44, 69),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
