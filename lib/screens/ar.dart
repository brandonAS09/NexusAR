import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/services/ar_service.dart';
import 'package:nexus_ar/screens/arReal.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> with WidgetsBindingObserver {
  final ArService _arService = ArService();
  
  // --- CAMBIO 1: Controlador NULLABLE (Para poder destruirlo y recrearlo) ---
  MobileScannerController? _cameraController;

  bool _isLoading = false;
  bool _showCard = false;
  
  // Esta variable controla si MOSTRAR el widget en el árbol
  bool _isScannerMounted = false;
  
  // Enfriamiento del escáner
  bool _scanCooldown = false; 

  Map<String, dynamic>? _classData;
  Offset? _qrPosition;
  Size? _cameraImageSize;

  @override
  void initState() {
    super.initState();
    // Registramos observador para manejar ciclo de vida de la app (minimizar/abrir)
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  // Manejo de ciclo de vida (si minimizas la app y vuelves)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_isScannerMounted) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController?.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.start();
    }
  }

  // --- NUEVO: INICIALIZAR ESCÁNER ---
  void _initializeScanner() {
    setState(() {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal, 
        returnImage: false,
        autoStart: false, 
      );
      _isScannerMounted = true;
    });
    // Pequeña espera para que el widget se monte antes de iniciar
    Future.delayed(const Duration(milliseconds: 100), () {
        _cameraController?.start();
    });
  }

  // --- NUEVO: DESTRUIR ESCÁNER COMPLETAMENTE ---
  Future<void> _disposeScanner() async {
    setState(() {
      _isScannerMounted = false; // Quita el widget de la pantalla
    });
    try {
      await _cameraController?.stop();
      // --- CORRECCIÓN AQUÍ: Quitamos 'await' porque dispose es void ---
      _cameraController?.dispose(); 
    } catch (e) {
      debugPrint("Error cerrando cámara: $e");
    }
    _cameraController = null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_showCard || _scanCooldown) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    _cameraImageSize = capture.size;

    if (barcode.corners != null && barcode.corners!.isNotEmpty) {
      final Offset center = _calculateQrCenter(barcode.corners!);
      _updateCardPosition(center);
    }

    print("🔍 SCANNER: Código detectado: $code");

    if (_qrPosition == null) {
      final screenSize = MediaQuery.of(context).size;
      _qrPosition = Offset(screenSize.width / 2, screenSize.height / 2);
    }

    setState(() {
      _isLoading = true;
      _showCard = true;
    });

    try {
      final result = await _arService.obtenerInfoClase(code);
      print("✅ SCANNER: Respuesta recibida: $result");

      if (mounted) {
        setState(() {
          _isLoading = false;
          _classData = result;
        });
      }
    } catch (e) {
      print("❌ SCANNER: Error en petición: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _classData = {'error': 'Error de conexión'};
        });
      }
    }
  }

  Offset _calculateQrCenter(List<Offset> corners) {
    double xSum = 0;
    double ySum = 0;
    for (var point in corners) {
      xSum += point.dx;
      ySum += point.dy;
    }
    return Offset(xSum / corners.length, ySum / corners.length);
  }

  void _updateCardPosition(Offset cameraPoint) {
    if (_cameraImageSize == null ||
        _cameraImageSize!.width <= 0 ||
        _cameraImageSize!.height <= 0) {
      return;
    }

    final screenSize = MediaQuery.of(context).size;

    double imgWidth = _cameraImageSize!.width;
    double imgHeight = _cameraImageSize!.height;

    double scaleX = screenSize.width / imgWidth;
    double scaleY = screenSize.height / imgHeight;

    double scale = (scaleX > scaleY) ? scaleX : scaleY;

    if (scale.isInfinite || scale.isNaN) return;

    double offsetX = (screenSize.width - imgWidth * scale) / 2;
    double offsetY = (screenSize.height - imgHeight * scale) / 2;

    final double screenX = cameraPoint.dx * scale + offsetX;
    final double screenY = cameraPoint.dy * scale + offsetY;

    if (screenX.isNaN || screenY.isNaN) return;

    if (_qrPosition == null ||
        (_qrPosition! - Offset(screenX, screenY)).distance > 5) {
      setState(() {
        _qrPosition = Offset(screenX, screenY);
      });
    }
  }

  Future<void> _navigateToRealAr() async {
    if (_classData != null) {
      
      // 1. DESTRUIMOS EL ESCÁNER ANTES DE SALIR
      // Esto libera la cámara totalmente para ARCore
      await _disposeScanner();

      if (!mounted) return;

      // 2. Navegamos
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RealArScreen(classData: _classData!),
        ),
      );

      // 3. AL VOLVER: Pausa de seguridad
      if (mounted) {
        debugPrint("🔄 Regresando de AR...");
        
        // Pausa para que ARCore suelte la cámara
        await Future.delayed(const Duration(milliseconds: 800));

        // 4. CREAMOS UN ESCÁNER NUEVO
        // Así aseguramos que no esté bloqueado o bugeado
        _initializeScanner();
        
        // Activamos cooldown breve para que no dispare inmediatamente
        setState(() {
          _scanCooldown = true; 
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _scanCooldown = false);
        });
      }
    }
  }

  void _simularPruebaVisual() {
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _isLoading = false;
      _showCard = true;
      _qrPosition = Offset(screenSize.width / 2, screenSize.height / 2);

      _classData = {
        'hay_clase': true,
        'datos': {
          'salon': 'Laboratorio Pollita',
          'materia': 'Programación Avanzada',
          'profesor': 'Prof. Alfredo Torres',
          'grupo': '777',
          'carrera': 'ISyTE',
        },
      };
    });
  }

  void _resetScan() {
    setState(() {
      _showCard = false;
      _classData = null;
      _qrPosition = null;
      _scanCooldown = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _scanCooldown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Solo mostramos MobileScanner si el controlador existe y está montado
          if (_isScannerMounted && _cameraController != null)
            MobileScanner(
              controller: _cameraController!, // Usamos ! porque verificamos que no es null
              onDetect: _onDetect,
              fit: BoxFit.cover,
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.botonInicioSesion)),

          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          if (_showCard &&
              _qrPosition != null &&
              !_qrPosition!.dx.isNaN &&
              !_qrPosition!.dy.isNaN)
            _buildArOverlay(),

          if (!_showCard)
            Positioned(
              bottom: 40,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.orangeAccent,
                icon: const Icon(Icons.bug_report, color: Colors.white),
                label: const Text(
                  "Prueba Visual",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _simularPruebaVisual,
              ),
            ),
        ],
      ),
    );
  }

  // --- Widgets UI (Overlay y Tarjeta) sin cambios ---
  Widget _buildArOverlay() {
    const double cardWidth = 300;

    double topPos = (_qrPosition!.dy - 180).clamp(
      0,
      MediaQuery.of(context).size.height - 200,
    );
    double leftPos = (_qrPosition!.dx - (cardWidth / 2)).clamp(
      0,
      MediaQuery.of(context).size.width - cardWidth,
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      left: leftPos,
      top: topPos,
      child: SizedBox(width: cardWidth, child: _buildArCard()),
    );
  }

  Widget _buildArCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.botonInicioSesion.withOpacity(0.85),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Analizando...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (_classData == null || _classData!.containsKey('error')) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 5),
          Text(
            _classData?['error'] ?? "Error desconocido", 
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resetScan, 
            style: TextButton.styleFrom(backgroundColor: Colors.white24),
            child: const Text("Cerrar", style: TextStyle(color: Colors.white))
          )
        ],
      );
    }

    final bool hayClase = _classData!['hay_clase'] == true;
    
    if (!hayClase) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, color: Colors.white, size: 40),
          const SizedBox(height: 5),
          Text(
            _classData!['mensaje'] ?? "Sin clase en este momento", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _resetScan,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple),
            child: const Text("Ok")
          ),
        ],
      );
    }

    final datos = _classData!['datos'];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Clase Detectada",
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), letterSpacing: 1.2),
          ),
        ),
        const Divider(color: Colors.white30, height: 15),
        
        _infoRow(Icons.room, "Salón:", datos['nombre_salon'] ?? 'N/A'),
        _infoRow(Icons.book, "Materia:", datos['materia'] ?? 'N/A'),
        _infoRow(Icons.person, "Profesor:", datos['NombreProfesor'] ?? 'N/A'),
        _infoRow(Icons.group, "Grupo:", datos['Grupo'] ?? 'N/A'),
        _infoRow(Icons.school, "Carrera:", datos['Carrera'] ?? 'N/A'),
        
        const SizedBox(height: 20),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _navigateToRealAr,
              icon: const Icon(Icons.view_in_ar, color: Colors.white),
              label: const Text("Ver en 3D (ARCore)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
            
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text("Escanear otro"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                children: [
                  TextSpan(
                    text: "$label ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}