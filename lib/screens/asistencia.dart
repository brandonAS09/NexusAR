import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // <-- ASEGÚRATE DE TENER 'geolocator' EN TU pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/qr.dart';
import 'package:nexus_ar/services/asistencia_service.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final AsistenciaService _service = AsistenciaService();

  // Estado de la UI
  bool _inProgress = false; // Muestra banner
  
  // Datos del usuario (cargados de Prefs)
  String? _userEmail; // <-- SOLO USAREMOS EL EMAIL

  // Estado de la sesión de asistencia
  int? _sessionUserId; // <-- ID de usuario OBTENIDO del backend
  int? _currentMateriaId;
  DateTime? _horaFinClase;
  bool _isUsuarioDentro = false; 
  Timer? _periodicTimer; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga SOLO Email del usuario desde SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Busca la llave 'email_usuario' que guardamos en el login
      _userEmail = prefs.getString('email_usuario');
    });
  }

  /// 1. Maneja permisos de Geolocalización
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El servicio de ubicación está deshabilitado.')));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los permisos de ubicación fueron denegados.')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los permisos de ubicación están denegados permanentemente.')));
      return false;
    }
    return true;
  }

  /// 2. Inicia el flujo completo al escanear QR
  Future<void> _openQrScanner() async {
    // CAMBIO: Validar solo el email
    if (_userEmail == null) {
      // Este es el error que te salía. Ahora no debería pasar si el login funciona.
      await _showErrorDialog(
        'Error de Autenticación', 
        'No se pudo cargar tu email de usuario. Por favor, vuelve a iniciar sesión.'
      );
      return;
    }

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      await _showErrorDialog('Permiso Requerido', 'Se requieren permisos de ubicación para registrar la asistencia.');
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );

    if (result == null || !mounted) return; 
    
    final String codigoSalon = result.trim();

    try {
      // 3. Obtener Horario (El backend busca el ID de usuario usando el email)
      final resp = await _service.obtenerHorario(codigoSalon, _userEmail!);
      
      if (resp['statusCode'] != 200 || resp['body'] == null) {
        final msg = resp['body']?['error'] ?? 'No se encontró una clase activa para este salón.';
        await _showErrorDialog('Error de Horario', msg);
        return;
      }

      final body = resp['body']!;
      // Capturamos el ID de usuario que devuelve el backend
      final int idUsuario = body['usuario']; 
      final int idMateria = body['id_materia'];
      final String horaFinStr = body['horario']['hora_fin'];

      final now = DateTime.now();
      final hf = horaFinStr.split(":");
      final horaFin = DateTime(now.year, now.month, now.day, int.parse(hf[0]), int.parse(hf[1]), int.parse(hf[2]));

      if (now.isAfter(horaFin)) {
        await _showErrorDialog('Clase Terminada', 'Esta clase ya ha finalizado.');
        return;
      }

      // 4. Mostrar modal de "Entendido" y activar banner
      await _showInitialDialog();
      setState(() {
        _inProgress = true;
        _currentMateriaId = idMateria;
        _horaFinClase = horaFin;
        _isUsuarioDentro = false; 
        _sessionUserId = idUsuario; // Guardamos el ID en el estado
      });

      // 5. Iniciar verificación periódica
      await _checkUbicacionYRegistrar(); 
      _periodicTimer?.cancel(); 
      _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkUbicacionYRegistrar();
      });

    } catch (e) {
      await _showErrorDialog('Error de Conexión', 'No se pudo contactar al servidor: ${e.toString()}');
    }
  }

  /// 4. (Helper) Muestra modal de inicio
  Future<void> _showInitialDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu asistencia está en curso.'),
        content: const Text('Se verificará tu ubicación periódicamente. Si sales del área, tu tiempo se pausará.'),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.botonInicioSesion,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text('Entendido'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. (Core) Función del timer: verifica ubicación y registra cambios
  Future<void> _checkUbicacionYRegistrar() async {
    // Si el timer sigue activo pero los datos se borraron, detener.
    if (_sessionUserId == null || _currentMateriaId == null) {
      _periodicTimer?.cancel();
      return;
    }

    if (_horaFinClase == null || DateTime.now().isAfter(_horaFinClase!)) {
      await _finalizarAsistencia("La clase ha terminado.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final resp = await _service.verificarUbicacion(position.latitude, position.longitude);

      if (resp['statusCode'] != 200 || resp['body'] == null) {
        print("Error verificando ubicación, se reintentará.");
        return;
      }

      final bool dentroEdificio = resp['body']!['dentro'] == true;
      final nowIso = DateTime.now().toIso8601String();

      // Usar _sessionUserId
      if (dentroEdificio && !_isUsuarioDentro) {
        print("Registrando ENTRADA");
        await _service.registrarEntrada(
          idUsuario: _sessionUserId!, 
          idMateria: _currentMateriaId!,
          timestamp: nowIso
        );
        setState(() { _isUsuarioDentro = true; });

      } else if (!dentroEdificio && _isUsuarioDentro) {
        print("Registrando SALIDA");
        await _service.registrarSalida(
          idUsuario: _sessionUserId!, 
          idMateria: _currentMateriaId!,
          timestamp: nowIso
        );
        setState(() { _isUsuarioDentro = false; });
      }
    } catch (e) {
      print("Error en _checkUbicacionYRegistrar: $e");
    }
  }

  /// 6. Finaliza la sesión (por tiempo o error) y consulta el estado final
  Future<void> _finalizarAsistencia(String titulo) async {
    _periodicTimer?.cancel();

    // Asegurarse de que los datos de sesión aún existan
    if (_sessionUserId == null || _currentMateriaId == null) {
      _limpiarEstado();
      return;
    }

    if (_isUsuarioDentro) {
      await _service.registrarSalida(
        idUsuario: _sessionUserId!, 
        idMateria: _currentMateriaId!,
        timestamp: DateTime.now().toIso8601String()
      );
    }
    
    final estadoResp = await _service.consultarEstado(
      idUsuario: _sessionUserId!, 
      idMateria: _currentMateriaId!
    );
    
    String mensajeFinal = titulo;
    if (estadoResp['statusCode'] == 200 && estadoResp['body'] != null) {
      mensajeFinal = estadoResp['body']!['mensaje'] ?? mensajeFinal;
    } else {
      mensajeFinal = "No se pudo consultar el estado final de la asistencia.";
    }

    _limpiarEstado();
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(mensajeFinal, textAlign: TextAlign.center),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.botonInicioSesion,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Text('Entendido'),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// 7. (Helper) Limpia el estado de la sesión
  void _limpiarEstado() {
    setState(() {
      _inProgress = false;
      _currentMateriaId = null;
      _horaFinClase = null;
      _isUsuarioDentro = false;
      _sessionUserId = null; 
    });
  }

  /// (Helper) Muestra un diálogo de error
  Future<void> _showErrorDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _periodicTimer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle purpleButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.botonInicioSesion,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      fixedSize: const Size(240, 120),
      elevation: 6,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.botonInicioSesion,
        title: const Text('Asistencia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MenuScreen(initialIndex: 1),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  ElevatedButton(
                    style: purpleButtonStyle,
                    onPressed: _inProgress ? null : _openQrScanner,
                    child: const Text(
                      'Asistencia\ncon QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 206),
                  ElevatedButton(
                    style: purpleButtonStyle,
                    onPressed: () {
                      // Aquí irá la pantalla de registro de asistencias
                    },
                    child: const Text(
                      'Registro de\nAsistencias',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Divider(
                    color: Colors.white54,
                    thickness: 1,
                    indent: 50,
                    endIndent: 50,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_inProgress)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.botonInicioSesion,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  _isUsuarioDentro
                      ? 'Asistencia en curso: Dentro del área.'
                      : 'Asistencia en pausa: Fuera del área.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}