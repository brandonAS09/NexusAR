import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:nexus_ar/core/app_colors.dart'; 

class RealArScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const RealArScreen({super.key, required this.classData});

  @override
  State<RealArScreen> createState() => _RealArScreenState();
}

class _RealArScreenState extends State<RealArScreen> {
  ArCoreController? arCoreController;

  @override
  void dispose() {
    // --- CORRECCIÓN CRÍTICA ---
    // Comentamos esta línea porque causaba que la app se cerrara (crash)
    // al intentar limpiar el controlador manualmente mientras se cerraba la pantalla.
    
    // arCoreController?.dispose(); 
    
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    _addInfoPanel();
  }

  Future<void> _addInfoPanel() async {
    final datos = widget.classData['datos'] ?? {};
    
    final String salon = datos['nombre_salon'] ?? datos['salon'] ?? "Salón";
    final String materia = datos['materia'] ?? "Materia";
    final String profesor = datos['NombreProfesor'] ?? datos['profesor'] ?? "Profesor";
    final String grupo = datos['Grupo'] ?? datos['grupo'] ?? "Grupo";
    final String carrera = datos['Carrera'] ?? datos['carrera'] ?? "Carrera";

    // 1. Generar textura
    final Uint8List imageBytes = await _createImageTexture(salon, materia, profesor, grupo, carrera);

    // 2. Material con textura
    final material = ArCoreMaterial(
      color: Colors.white,
      textureBytes: imageBytes,
      metallic: 1.0, 
    );

    // 3. Panel plano
    final panelShape = ArCoreCube(
      materials: [material],
      size: vector.Vector3(1.2, 0.8, 0.01), 
    );

    // 4. Nodo en el espacio
    final panelNode = ArCoreNode(
      shape: panelShape,
      position: vector.Vector3(0, 0, -1.5),
    );

    arCoreController?.addArCoreNode(panelNode);
  }

  Future<Uint8List> _createImageTexture(String salon, String materia, String prof, String grupo, String carrera) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    const int width = 600;
    const int height = 400;
    
    // --- ESTILO MORADO ---
    final paint = Paint()
      ..color = AppColors.botonInicioSesion.withOpacity(0.85) 
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), 
      const Radius.circular(40)
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    // --- TEXTOS ---

    // 1. SALÓN
    final salonPainter = TextPainter(
      text: TextSpan(
        text: salon,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 35, 
          fontWeight: FontWeight.bold
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 2. MATERIA
    final materiaPainter = TextPainter(
      text: TextSpan(
        text: materia,
        style: const TextStyle(
          color: Colors.cyanAccent, 
          fontSize: 50, 
          fontWeight: FontWeight.bold
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );

    // 3. DETALLES
    final detallesPainter = TextPainter(
      text: TextSpan(
        text: "$prof\n Grupo: $grupo\n $carrera",
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 28,
          height: 1.5 
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    salonPainter.layout(maxWidth: width - 40.0);
    materiaPainter.layout(maxWidth: width - 40.0);
    detallesPainter.layout(maxWidth: width - 40.0);

    double currentY = 40; 

    salonPainter.paint(canvas, Offset((width - salonPainter.width) / 2, currentY));
    currentY += salonPainter.height + 20;

    final linePaint = Paint()..color = Colors.white30..strokeWidth = 2;
    canvas.drawLine(Offset(50, currentY), Offset(width - 50.0, currentY), linePaint);
    currentY += 20;

    materiaPainter.paint(canvas, Offset((width - materiaPainter.width) / 2, currentY));
    currentY += materiaPainter.height + 20;

    detallesPainter.paint(canvas, Offset((width - detallesPainter.width) / 2, currentY));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Información AR"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.black,
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true,
      ),
    );
  }
}