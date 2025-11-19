import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/qr.dart';
import 'package:nexus_ar/services/asistencia_service.dart';
import 'package:nexus_ar/components/asistencia_dialogs.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final AsistenciaService _service = AsistenciaService();

  bool _inProgress = false;
  String? _userEmail;
  int? _sessionUserId;
  int? _currentMateriaId;
  int? _currentEdificioId; // <-- NUEVO: Guardamos el ID del edificio
  int? _duracionClaseMinutos; // <-- NUEVO: Para el cronómetro (opcional visualmente)
  DateTime? _horaFinClase;
  bool _isUsuarioDentro = false;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email_usuario');
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El servicio de ubicación está deshabilitado.')),
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación fueron denegados.')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos de ubicación están denegados permanentemente.')),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _openQrScanner() async {
    if (_userEmail == null) {
      await AsistenciaDialogs.showError(
        context,
        'Error de Autenticación',
        'No se pudo cargar tu email de usuario. Por favor, vuelve a iniciar sesión.',
      );
      return;
    }

    // 1. Pedir permisos de ubicación ANTES de todo
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      await AsistenciaDialogs.showError(
        context,
        'Permiso Requerido',
        'Se requieren permisos de ubicación para registrar la asistencia.',
      );
      return;
    }

    // 2. Escanear QR
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );

    if (result == null || !mounted) return;
    final String codigoSalon = result.trim();

    try {
      // 3. OBTENER GPS ACTUAL (Requisito nuevo del backend)
      // Debemos enviar la ubicación junto con el código QR para la validación inicial
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 4. Llamar al endpoint /horario enviando lat/lon
      final resp = await _service.obtenerHorario(
        codigoSalon, 
        _userEmail!, 
        position.latitude, 
        position.longitude
      );

      // Manejo de Errores
      if (resp['statusCode'] != 200 || resp['body'] == null) {
        final msg = resp['body']?['error'] ?? 'Error desconocido.';
        
        // Manejo específico del Error 403 (Fuera de rango)
        if (resp['statusCode'] == 403) {
             await AsistenciaDialogs.showError(context, 'Ubicación Inválida', msg);
        } else {
             await AsistenciaDialogs.showError(context, 'Error de Horario', msg);
        }
        return;
      }

      // 5. Procesar Respuesta Exitosa
      final body = resp['body']!;
      final int idUsuario = body['usuario'];
      final int idMateria = body['id_materia'];
      final int idEdificio = body['id_edificio']; // <-- NUEVO: Guardar esto
      // final int duracionClase = body['duracion_clase']; // Opcional guardar

      final String horaFinStr = body['horario']['hora_fin'];
      final now = DateTime.now();
      final hf = horaFinStr.split(":");
      final horaFin = DateTime(now.year, now.month, now.day, int.parse(hf[0]), int.parse(hf[1]), int.parse(hf[2]));

      if (now.isAfter(horaFin)) {
        await AsistenciaDialogs.showError(
          context,
          'Clase Terminada',
          'Esta clase ya ha finalizado.',
        );
        return;
      }

      // 6. Iniciar Sesión de Asistencia (Entrada Inicial)
      await AsistenciaDialogs.showInitial(context);
      
      // Registrar entrada en BD (Login)
      final nowIso = DateTime.now().toIso8601String();
      await _service.registrarEntrada(
          idUsuario: idUsuario,
          idMateria: idMateria,
          timestamp: nowIso,
      );

      setState(() {
        _inProgress = true;
        _currentMateriaId = idMateria;
        _currentEdificioId = idEdificio; // <-- Guardamos el edificio para el chequeo periódico
        _horaFinClase = horaFin;
        _isUsuarioDentro = true; // Asumimos true porque /horario ya validó que estamos dentro
        _sessionUserId = idUsuario;
      });

      // 7. Iniciar Timer Periódico
      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkUbicacionYRegistrar();
      });

    } catch (e) {
      await AsistenciaDialogs.showError(
        context,
        'Error de Conexión',
        'No se pudo contactar al servidor: ${e.toString()}',
      );
    }
  }

  Future<void> _checkUbicacionYRegistrar() async {
    if (_sessionUserId == null || _currentMateriaId == null || _currentEdificioId == null) {
      _periodicTimer?.cancel();
      return;
    }

    if (_horaFinClase == null || DateTime.now().isAfter(_horaFinClase!)) {
      await _finalizarAsistencia("La clase ha terminado.");
      return;
    }

    try {
      // 1. Obtener GPS actualizado
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 2. Verificar ubicación enviando el ID DEL EDIFICIO
      final resp = await _service.verificarUbicacion(
        _currentEdificioId!, // Enviamos el ID que obtuvimos al inicio
        position.latitude, 
        position.longitude
      );

      if (resp['statusCode'] != 200 || resp['body'] == null) {
        print("Error verificando ubicación, se reintentará.");
        return;
      }

      final bool dentroEdificio = resp['body']!['dentro'] == true;
      final nowIso = DateTime.now().toIso8601String();

      // 3. Lógica de Entrada/Salida según respuesta
      if (dentroEdificio && !_isUsuarioDentro) {
        // Estaba fuera, ahora entró -> Registrar Entrada
        print("Re-Ingresando al aula");
        await _service.registrarEntrada(
          idUsuario: _sessionUserId!,
          idMateria: _currentMateriaId!,
          timestamp: nowIso,
        );
        setState(() => _isUsuarioDentro = true);

      } else if (!dentroEdificio && _isUsuarioDentro) {
        // Estaba dentro, ahora salió -> Registrar Salida
        print("Saliendo del aula (Pausando)");
        await _service.registrarSalida(
          idUsuario: _sessionUserId!,
          idMateria: _currentMateriaId!,
          timestamp: nowIso,
        );
        setState(() => _isUsuarioDentro = false);
      }
      // Si (dentro && _isUsuarioDentro) -> Sigue todo bien, no hacer nada.
      // Si (!dentro && !_isUsuarioDentro) -> Sigue fuera, no hacer nada.

    } catch (e) {
      print("Error en _checkUbicacionYRegistrar: $e");
    }
  }

  Future<void> _finalizarAsistencia(String titulo) async {
    _periodicTimer?.cancel();

    if (_sessionUserId == null || _currentMateriaId == null) {
      _limpiarEstado();
      return;
    }

    // Si terminamos y el usuario seguía dentro, cerramos su sesión
    if (_isUsuarioDentro) {
      await _service.registrarSalida(
        idUsuario: _sessionUserId!,
        idMateria: _currentMateriaId!,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    final estadoResp = await _service.consultarEstado(
      idUsuario: _sessionUserId!,
      idMateria: _currentMateriaId!,
    );

    String mensajeFinal = titulo;
    if (estadoResp['statusCode'] == 200 && estadoResp['body'] != null) {
      mensajeFinal = estadoResp['body']!['mensaje'] ?? mensajeFinal;
    } else {
      mensajeFinal = "No se pudo consultar el estado final de la asistencia.";
    }

    _limpiarEstado();
    if (mounted) {
      await AsistenciaDialogs.showFinal(context, mensajeFinal);
    }
  }

  void _limpiarEstado() {
    setState(() {
      _inProgress = false;
      _currentMateriaId = null;
      _currentEdificioId = null;
      _horaFinClase = null;
      _isUsuarioDentro = false;
      _sessionUserId = null;
    });
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
              MaterialPageRoute(builder: (context) => const MenuScreen(initialIndex: 1)),
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
                    onPressed: () {}, // Lógica de registro manual pendiente
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