import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/logros.dart';

class LogrosAsistenciaScreen extends StatefulWidget {
  const LogrosAsistenciaScreen({super.key});

  @override
  State<LogrosAsistenciaScreen> createState() =>
      _LogrosAsistenciaScreenState();
}

class _LogrosAsistenciaScreenState extends State<LogrosAsistenciaScreen> {
  final List<Map<String, dynamic>> listaLogros = [
    {
      "texto": "5 Asistencias Completadas Seguidas",
      "desbloqueado": false,
      "imagen": "assets/images/Baby_Asistencia5.png"
    },
    {
      "texto": "10 Asistencias Completadas Seguidas",
      "desbloqueado": false,
      "imagen": "assets/images/Junior_Asistencia10.png"
    },
    {
      "texto": "15 Asistencias Completadas Seguidas",
      "desbloqueado": false,
      "imagen": "assets/images/Mid_Asistencia15.png"
    },
    {
      "texto": "20 Asistencias Completadas Seguidas",
      "desbloqueado": false,
      "imagen": "assets/images/Senior_Asistencia20.png"
    },
    {
      "texto": "25 Asistencias Completadas Seguidas",
      "desbloqueado": false,
      "imagen": "assets/images/Pro_Asistencia25.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LogrosScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            itemCount: listaLogros.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final logro = listaLogros[index];
              return LogroCard(
                texto: logro['texto'],
                esDesbloqueado: logro['desbloqueado'],
                imageAsset: logro['imagen'], 
              );
            },
          ),
        ),
      ),
    );
  }
}
class LogroCard extends StatelessWidget {
  final String texto;
  final bool esDesbloqueado;
  final String? imageAsset;

  const LogroCard({
    super.key,
    required this.texto,
    required this.esDesbloqueado,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.botonInicioSesion,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // imagen
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageAsset != null 
                ? Image.asset(
                    imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 40),
                  ) 
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          
          const SizedBox(width: 12),

          // texto
          Expanded(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1
              ),
            ),
          ),

          const SizedBox(width: 12),

          // icono
          Icon(
            esDesbloqueado ? Icons.check : Icons.lock,
            color: Colors.black,
            size: 32,
          ),
        ],
      ),
    );
  }
}