import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';

class LogrosAsistenciaScreen extends StatefulWidget {
  // Recibimos la racha actual desde la pantalla anterior
  final int rachaActual;

  const LogrosAsistenciaScreen({super.key, required this.rachaActual});

  @override
  State<LogrosAsistenciaScreen> createState() => _LogrosAsistenciaScreenState();
}

class _LogrosAsistenciaScreenState extends State<LogrosAsistenciaScreen> {
  
  // Definimos la lista con la propiedad 'meta' para calcular el desbloqueo
  List<Map<String, dynamic>> get listaLogros => [
    {
      "texto": "5 Asistencias Completadas Seguidas",
      "meta": 5,
      "imagen": "assets/images/Baby_Asistencia5.png"
    },
    {
      "texto": "10 Asistencias Completadas Seguidas",
      "meta": 10,
      "imagen": "assets/images/Junior_Asistencia10.png"
    },
    {
      "texto": "15 Asistencias Completadas Seguidas",
      "meta": 15,
      "imagen": "assets/images/Mid_Asistencia15.png"
    },
    {
      "texto": "20 Asistencias Completadas Seguidas",
      "meta": 20,
      "imagen": "assets/images/Senior_Asistencia20.png"
    },
    {
      "texto": "25 Asistencias Completadas Seguidas",
      "meta": 25,
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
             Navigator.pop(context);
          },
        ),
        title: const Text(
          "Logros de Asistencia", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
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
              final int meta = logro['meta'];

              // Cálculo dinámico: ¿La racha actual supera la meta?
              final bool estaDesbloqueado = widget.rachaActual >= meta;

              return LogroCard(
                texto: logro['texto'],
                esDesbloqueado: estaDesbloqueado,
                imageAsset: logro['imagen'], 
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- CLASE LOGROCARD COMPLETA ---
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
          // 1. Imagen del Logro
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            // Lógica visual: Si está bloqueado, le bajamos la opacidad a la imagen
            child: imageAsset != null 
                ? Opacity(
                    opacity: esDesbloqueado ? 1.0 : 0.5, 
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 40),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          
          const SizedBox(width: 12),

          // 2. Texto descriptivo
          Expanded(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                // Lógica visual: Si está bloqueado, el texto se ve gris
                color: esDesbloqueado ? Colors.black : Colors.grey[700], 
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 3. Icono de estado (Candado o Check)
          Icon(
            esDesbloqueado ? Icons.check_circle : Icons.lock,
            // Lógica visual: Verde oscuro si se logró, negro si está bloqueado
            color: esDesbloqueado ? Colors.green[800] : Colors.black,
            size: 32,
          ),
        ],
      ),
    );
  }
}