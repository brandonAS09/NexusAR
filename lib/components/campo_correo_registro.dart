import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class CampoCorreoRegistro extends StatelessWidget {
  const CampoCorreoRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(10));

    final baseDecoration = InputDecoration(
      border: InputBorder.none,
      enabledBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none
      ),
      filled: true,
      fillColor: AppColors.fieldTextColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      hintStyle: const TextStyle(color: Colors.white, fontSize: 16)
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Campo para ingresar texto
          Expanded(
            flex: 2,
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: baseDecoration.copyWith(
                hintText: "Correo Electrónico"
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // texto uabc
          Expanded(
            flex: 1,
            child: Container(
              height: 60,
              alignment: Alignment.centerLeft,
              child: const Text(
                "@uabc.edu.mx",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}