import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
// import 'package:nexus_ar/screens/logros.dart'; // Si lo necesitas para volver, aunque el pop funciona bien.

class LogrosPuntualidadScreen extends StatefulWidget {
  // Aceptamos la racha como parámetro
  final int rachaActual;

  const LogrosPuntualidadScreen({super.key, required this.rachaActual});

  @override
  State<LogrosPuntualidadScreen> createState() => _LogrosPuntualidadScreenState();
}

class _LogrosPuntualidadScreenState extends State<LogrosPuntualidadScreen> {
  
  // Convertimos la lista en una función o getter para calcular el desbloqueo dinámicamente
  List<Map<String, dynamic>> get listaLogros => [
    {
      "texto": "5 Puntualidades\nPerfectas Seguidas",
      "meta": 5, // Agregamos la meta numérica
      "imagen": "assets/images/Baby_Puntualidad5.png"
    },
    {
      "texto": "10 Puntualidades\nPerfectas Seguidas",
      "meta": 10,
      "imagen": "assets/images/Junior_Puntualidad10.png"
    },
    {
      "texto": "15 Puntualidades\nPerfectas Seguidas",
      "meta": 15,
      "imagen": "assets/images/Mid_Puntualidad15.png"
    },
    {
      "texto": "20 Puntualidades\nPerfectas Seguidas",
      "meta": 20,
      "imagen": "assets/images/Senior_Puntualidad20.png"
    },
    {
      "texto": "25 Puntualidades\nPerfectas Seguidas",
      "meta": 25,
      "imagen": "assets/images/Pro_Puntualidad25.png"
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
            // Simplemente hacemos pop para volver a la pantalla anterior manteniendo el estado
            Navigator.pop(context); 
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
              final int meta = logro['meta'];
              
              // Aquí ocurre la magia: comparamos la racha real con la meta del logro
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

// ... LogroCard se mantiene igual ...
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
          // Imagen con filtro de color si está bloqueado (opcional, visualmente ayuda)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageAsset != null 
                ? Opacity(
                    opacity: esDesbloqueado ? 1.0 : 0.5, // Más transparente si está bloqueado
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 40),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: esDesbloqueado ? Colors.black : Colors.grey[700], // Gris si está bloqueado
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1
              ),
            ),
          ),

          const SizedBox(width: 12),

          Icon(
            esDesbloqueado ? Icons.check_circle : Icons.lock, // Icono más claro
            color: esDesbloqueado ? Colors.green[800] : Colors.black,
            size: 32,
          ),
        ],
      ),
    );
  }
}