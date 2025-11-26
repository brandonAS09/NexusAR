import 'dart:async';
import 'dart:ui'; // Necesario para FontFeature
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/screens/menu.dart';
import 'package:nexus_ar/screens/qr.dart';
import 'package:nexus_ar/services/asistencia_service.dart';
import 'package:nexus_ar/components/asistencia_dialogs.dart';
import 'package:nexus_ar/screens/registro_asistencias.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final AsistenciaService _service = AsistenciaService();

  // Estado General
  bool _inProgress = false;
  String? _userEmail;
  
  // Datos de la Sesión Actual
  int? _sessionUserId;
  int? _currentMateriaId;
  int? _currentEdificioId;
  DateTime? _horaFinClase;
  
  // Estado de Ubicación
  bool _isUsuarioDentro = false;
  Timer? _periodicTimer;

  // Contadores
  int _secondsRemaining = 0; // Tiempo que falta para llegar al 80%
  int _secondsElapsedCheck = 0; // Contador interno para checar GPS

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

  // Formato de tiempo MM:SS (Ej: 45:02)
  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00";
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Manejo de Permisos GPS
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El GPS está desactivado.')));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permisos de ubicación denegados.')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permisos denegados permanentemente.')));
      return false;
    }
    return true;
  }

  // --- INICIO DEL PROCESO (ESCANEO) ---
  Future<void> _openQrScanner() async {
    if (_userEmail == null) {
      await AsistenciaDialogs.showError(context, 'Error', 'No se ha cargado el usuario. Reinicia la app.');
      return;
    }

    if (!await _handleLocationPermission()) return;

    // 1. Escanear
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );

    if (result == null || !mounted) return;
    final String codigoSalon = result.trim();

    try {
      // 2. Obtener GPS para validación inicial
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 3. Llamar al Backend (/horario)
      final resp = await _service.obtenerHorario(
        codigoSalon,
        _userEmail!,
        position.latitude,
        position.longitude,
      );

      // Manejo de errores del backend
      if (resp['statusCode'] != 200 || resp['body'] == null) {
        final msg = resp['body']?['error'] ?? 'Error desconocido.';
        if (resp['statusCode'] == 403) {
          // Error de Geofence
          await AsistenciaDialogs.showError(context, 'Ubicación Inválida', msg);
        } else {
          await AsistenciaDialogs.showError(context, 'Error de Horario', msg);
        }
        return;
      }

      // --- 4. PROCESAR RESPUESTA EXITOSA ---
      final body = resp['body']!;
      
      final int idUsuario = body['usuario'] ?? 0;
      final int idMateria = body['id_materia'] ?? 0;
      final int idEdificio = body['id_edificio'] ?? 0;
      // IMPORTANTE: Recibimos la duración total en minutos desde el backend
      final int duracionTotalMinutos = body['duracion_clase'] ?? 60;

      final String horaFinStr = body['horario']['hora_fin'];
      final now = DateTime.now();
      final hf = horaFinStr.split(":");
      final horaFin = DateTime(now.year, now.month, now.day, int.parse(hf[0]), int.parse(hf[1]), int.parse(hf[2]));

      if (now.isAfter(horaFin)) {
        await AsistenciaDialogs.showError(context, 'Clase Terminada', 'Esta clase ya ha finalizado por horario.');
        return;
      }

      // 5. Mostrar diálogo de inicio
      await AsistenciaDialogs.showInitial(context);

      final nowIso = DateTime.now().toIso8601String();
      
      // REGISTRO DE ENTRADA Y FEEDBACK DE PUNTUALIDAD
      final entradaResp = await _service.registrarEntrada(
        idUsuario: idUsuario,
        idMateria: idMateria,
        timestamp: nowIso,
      );

      if (mounted) {
          if (entradaResp['statusCode'] == 201 && entradaResp['body'] != null) {
            final bool esPuntual = entradaResp['body']['puntual'] == true;
            
            // ¡AQUÍ ESTÁ LA MAGIA! 🎉
            if (esPuntual) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.access_alarm, color: Colors.white),
                      SizedBox(width: 10),
                      Text("¡Llegaste a tiempo! +1 Racha Puntualidad 🎯", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: Colors.green[700],
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                )
              );
            }
          }
      }

      // --- CÁLCULO DEL CRONÓMETRO (80%) ---
      // Convertimos minutos a segundos y sacamos el 80%
      final int totalSegundosClase = duracionTotalMinutos * 60;
      final int segundosNecesarios = (totalSegundosClase * 0.80).round();

      setState(() {
        _inProgress = true;
        _currentMateriaId = idMateria;
        _currentEdificioId = idEdificio;
        _horaFinClase = horaFin;
        _isUsuarioDentro = true; // Asumimos true porque /horario ya validó geofence
        _sessionUserId = idUsuario;
        
        // Inicializamos el contador regresivo
        _secondsRemaining = segundosNecesarios; 
        _secondsElapsedCheck = 0;
      });

      // 6. Iniciar el Timer (Corre cada 1 segundo)
      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _tickTimer());

    } catch (e) {
      await AsistenciaDialogs.showError(context, 'Error de Conexión', e.toString());
    }
  }

  // --- LÓGICA DEL TIMER (SE EJECUTA CADA SEGUNDO) ---
  void _tickTimer() {
    // A. Si ya se cumplió el tiempo, no hacemos nada más (esperamos finalizar)
    if (_secondsRemaining <= 0) return;

    // B. Validar si la clase terminó por hora reloj
    if (_horaFinClase != null && DateTime.now().isAfter(_horaFinClase!)) {
      _finalizarAsistencia("La clase ha terminado por horario.");
      return;
    }

    // C. Lógica del Cronómetro: Solo resta si está DENTRO
    if (_isUsuarioDentro && _secondsRemaining > 0) {
      setState(() {
        _secondsRemaining--;
      });
    }

    // D. Chequeo de VICTORIA: Si llega a 0, terminamos
    if (_secondsRemaining <= 0) {
      _finalizarAsistencia("¡Asistencia Completada!\nHas cumplido con el tiempo requerido.");
      return;
    }

    // E. Chequeo de UBICACIÓN con el Backend (Cada 10 segundos)
    _secondsElapsedCheck++;
    // CAMBIO: Reducido de 30 a 10 segundos para mayor precisión
    if (_secondsElapsedCheck >= 10) {
      _secondsElapsedCheck = 0; // Reiniciar contador auxiliar
      _checkUbicacionBackend(); // Llamada asíncrona al backend
    }
  }

  // --- VERIFICACIÓN DE UBICACIÓN (BACKGROUND) ---
  Future<void> _checkUbicacionBackend() async {
    if (_sessionUserId == null || _currentEdificioId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final resp = await _service.verificarUbicacion(
        _currentEdificioId!, 
        position.latitude, 
        position.longitude
      );

      // LÓGICA CORREGIDA: Manejar tanto el éxito (200) como el rechazo (403)
      bool nuevoEstadoDentro = false;

      if (resp['statusCode'] == 200) {
        // Si es 200, el backend dice que estamos dentro
        nuevoEstadoDentro = true;
        // Opcional: si tu service devuelve un campo explícito, úsalo:
        if (resp['body'] != null && resp['body']['dentro'] != null) {
          nuevoEstadoDentro = resp['body']['dentro'] == true;
        }
      } else if (resp['statusCode'] == 403) {
        // Si es 403, el backend dice que estamos FUERA
        nuevoEstadoDentro = false;
      } else {
        // Si es otro error (500, 404), ignoramos este ciclo por seguridad
        debugPrint("Error verificando ubicación (Status ${resp['statusCode']}), ignorando este ciclo.");
        return;
      }

      final nowIso = DateTime.now().toIso8601String();

      // Cambios de estado:
      if (nuevoEstadoDentro && !_isUsuarioDentro) {
        // Estaba fuera y ahora entró -> Registrar Entrada
        debugPrint("📍 Usuario volvió al área.");
        await _service.registrarEntrada(
          idUsuario: _sessionUserId!,
          idMateria: _currentMateriaId!,
          timestamp: nowIso,
        );
        if (mounted) setState(() => _isUsuarioDentro = true);

      } else if (!nuevoEstadoDentro && _isUsuarioDentro) {
        // Estaba dentro y ahora salió -> Registrar Salida (Pausa)
        debugPrint("⚠️ Usuario salió del área.");
        
        // Notificación visual rápida (opcional)
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ ¡Has salido del área! El tiempo se ha pausado."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            )
          );
        }

        await _service.registrarSalida(
          idUsuario: _sessionUserId!,
          idMateria: _currentMateriaId!,
          timestamp: nowIso,
        );
        if (mounted) setState(() => _isUsuarioDentro = false);
      }
    } catch (e) {
      debugPrint("Excepción en checkUbicacionBackend: $e");
    }
  }

  // --- FINALIZAR ASISTENCIA ---
  Future<void> _finalizarAsistencia(String titulo) async {
    _periodicTimer?.cancel();

    if (_sessionUserId == null || _currentMateriaId == null) {
      _limpiarEstado();
      return;
    }

    // Si termina estando dentro, cerramos la sesión en BD
    if (_isUsuarioDentro) {
      await _service.registrarSalida(
        idUsuario: _sessionUserId!,
        idMateria: _currentMateriaId!,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    // Consultar estado final (porcentaje real) para mostrar mensaje
    final estadoResp = await _service.consultarEstado(
      idUsuario: _sessionUserId!,
      idMateria: _currentMateriaId!,
    );

    String mensajeFinal = titulo;
    if (estadoResp['statusCode'] == 200 && estadoResp['body'] != null) {
      // AQUÍ el backend enviará "Tu asistencia fue registrada... ¡Punto de asistencia sumado!"
      String msgBackend = estadoResp['body']!['mensaje'] ?? "";
      mensajeFinal = "$titulo\n\n$msgBackend";
    }

    if (mounted) {
        _limpiarEstado();
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
      _secondsRemaining = 0;
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
          // --- CONTENIDO PRINCIPAL (BOTONES) ---
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  ElevatedButton(
                    style: purpleButtonStyle,
                    // Deshabilitar botón si ya hay asistencia en curso
                    onPressed: _inProgress ? null : _openQrScanner,
                    child: const Text(
                      'Asistencia\ncon QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 206),
                  ElevatedButton(
                    style: purpleButtonStyle,
                    onPressed: () {
                      Navigator.push( context, 
                      MaterialPageRoute(builder: (context) => const RegistroAsistenciasScreen())
                      );
                    }, // Funcionalidad futura
                    child: const Text(
                      'Registro de\nAsistencias',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  const Divider(color: Colors.white54, thickness: 1, indent: 50, endIndent: 50),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- BANNER INFERIOR MEJORADO ---
          if (_inProgress)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                // Color: Morado si está dentro, Rojo si está fuera
                color: _isUsuarioDentro ? AppColors.botonInicioSesion : Colors.red[800],
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                
                // Usamos ROW para poner texto a la izquierda y contador a la derecha
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LADO IZQUIERDO: Icono y Estado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isUsuarioDentro ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: _isUsuarioDentro ? Colors.black : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isUsuarioDentro ? "DENTRO DEL ÁREA" : "FUERA DEL ÁREA",
                                style: TextStyle(
                                  color: _isUsuarioDentro ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isUsuarioDentro 
                              ? "Tu asistencia se está registrando." 
                              : "Cronómetro en PAUSA.",
                            style: TextStyle(
                              color: _isUsuarioDentro ? Colors.black87 : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // LADO DERECHO: El Contador Grande
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1), // Fondo sutil para el número
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "RESTANTE",
                             style: TextStyle(
                              color: _isUsuarioDentro ? Colors.black54 : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0
                            ),
                          ),
                          Text(
                            _formatTime(_secondsRemaining),
                            style: TextStyle(
                              color: _isUsuarioDentro ? Colors.black : Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              // Esto evita que los números salten de ancho
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}