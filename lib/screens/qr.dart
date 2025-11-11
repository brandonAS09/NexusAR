import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nexus_ar/core/app_colors.dart';

/// Pantalla simple para escanear QR con la cámara. EL QR VA RECIBIR CODIGO, QUE EN ESTE CASO VA SER EL DE ID DEL SALON Y TAMBIEN EL EMAIL
/// Al detectar un código válido hace `Navigator.pop(context, rawValue)`.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _isProcessing = true;
    // Devuelve el texto leído al caller
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo negro para la vista de cámara
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Escanear QR', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            //allowDuplicates: false,
            onDetect: _onDetect,
          ),
          // Overlay simple con línea guía
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.botonInicioSesion,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.flashlight_on),
                label: const Text('Linterna'),
                onPressed: () async {
                  // Alterna linterna
                  await _controller.toggleTorch();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}