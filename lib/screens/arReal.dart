import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para cargar fuentes si es necesario
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
    arCoreController?.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    _addInfoPanel();
  }

  Future<void> _addInfoPanel() async {
    final datos = widget.classData['datos'] ?? {};
    final String materia = datos['materia'] ?? "Materia";
    final String profesor = datos['profesor'] ?? "Profesor";
    final String salon = datos['salon'] ?? "Salón";

    // 1. Generar textura
    final Uint8List imageBytes = await _createImageTexture(materia, profesor, salon);

    // 2. Material con textura
    final material = ArCoreMaterial(
      color: Colors.white,
      textureBytes: imageBytes,
      metallic: 1.0,
    );

    // 3. Panel plano
    final panelShape = ArCoreCube(
      materials: [material],
      size: vector.Vector3(1.0, 0.6, 0.01),
    );

    // 4. Nodo en el espacio
    final panelNode = ArCoreNode(
      shape: panelShape,
      position: vector.Vector3(0, 0, -1.5),
    );

    arCoreController?.addArCoreNode(panelNode);
  }

  Future<Uint8List> _createImageTexture(String title, String subtitle, String extra) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    const int width = 500;
    const int height = 300;
    
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    // --- CORRECCIÓN AQUÍ ---
    // Quitamos 'const' porque .toDouble() no es constante
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), 
      const Radius.circular(30)
    );
    // -----------------------

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.cyanAccent, 
          fontSize: 45, 
          fontWeight: FontWeight.bold
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );

    final bodyPainter = TextPainter(
      text: TextSpan(
        text: "$subtitle\n$extra",
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 30
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    titlePainter.layout(minWidth: 0, maxWidth: width - 40.0);
    bodyPainter.layout(minWidth: 0, maxWidth: width - 40.0);

    final double titleHeight = titlePainter.height;
    final double bodyHeight = bodyPainter.height;
    final double totalContentHeight = titleHeight + bodyHeight + 20;
    final double startY = (height - totalContentHeight) / 2;

    titlePainter.paint(canvas, Offset((width - titlePainter.width) / 2, startY));
    bodyPainter.paint(canvas, Offset((width - bodyPainter.width) / 2, startY + titleHeight + 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AR Real 3D"),
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