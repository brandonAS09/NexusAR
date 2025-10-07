import 'package:flutter/material.dart';

class InicioSesion extends StatelessWidget {
  const InicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 32,),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Correo",
              icon: Icon(Icons.email),
              border: OutlineInputBorder()
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Contraseña",
              icon: Icon(Icons.remove_red_eye),
              border: OutlineInputBorder()
            ),
          ),
          )
      ],
    );
  }
}