import 'package:flutter/material.dart';

class RequisitosContra extends StatelessWidget {
  const RequisitosContra({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> requisitos = [
      "Mínimo 8 caracteres",
      "Incluir mínimo una letra Mayúscula (A - Z)",
      "Incluir mínimo una letra Minúscula (a - z)",
      "Incluir mínimo un número (0 - 9)",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: requisitos
            .map(
              (req) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $req',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
