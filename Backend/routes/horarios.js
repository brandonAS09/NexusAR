const express = require("express");
const router = express.Router();
const db = require("../db");

router.post("/horario", async (req, res) => {

  // 1. OBTENEMOS LOS DATOS REQUERIDOS DESDE FLUTTER
  const { codigo, email, latitud, longitud } = req.body;

  if (!codigo || !email || !latitud || !longitud) {
    return res.status(400).json({ error: "Faltan datos (código, email o ubicación)." });
  }

  try {
    // 2. OBTENER ID DEL USUARIO
    const [userResult] = await db.query(
      "SELECT id_usuario FROM Usuarios WHERE CorreoUsuario = ?",
      [email]
    );

    if (userResult.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado." });
    }
    const id_usuario = userResult[0].id_usuario;

    // 3. VALIDACIÓN DE GEOFENCE
    const userLocationPoint = `POINT(${longitud} ${latitud})`;

    const sqlGeofence = `
       SELECT 
         E.nombre AS nombre_edificio,
         S.id_edificio,  -- IMPORTANTE: Añadido para devolverlo al frontend
         ST_Contains(E.ubicacion, ST_GeomFromText(?, ?)) AS esta_dentro
       FROM Salones S
       JOIN Edificios E ON S.id_edificio = E.id
       WHERE S.id_salon = ?;
     `;

    const [geofenceResult] = await db.query(sqlGeofence, [userLocationPoint, 4326, codigo]);

    if (geofenceResult.length === 0) {
      return res.status(404).json({ error: "Salón no encontrado o no está asignado a un edificio." });
    }

    const esta_dentro = geofenceResult[0].esta_dentro;

    // 4. BLOQUEO DE SEGURIDAD
    if (esta_dentro === 0) {
      return res.status(403).json({
        error: `Acceso denegado. Debes estar dentro del edificio '${geofenceResult[0].nombre_edificio}' para registrar tu asistencia.`
      });
    }

    // 5. VALIDACIÓN DE HORARIO
    const sqlHorario = `
       SELECT 
         M.id AS id_materia, 
         M.nombre AS nombre_materia, 
         M.duracion_minutos,
         H.dia, 
         H.hora_inicio, 
         H.hora_fin
       FROM Horarios H
       JOIN Materias M ON H.id_materia = M.id
       WHERE H.id_salon = ?
         AND H.dia = (
           CASE DAYOFWEEK(NOW())
             WHEN 2 THEN 'Lunes'
             WHEN 3 THEN 'Martes'
             WHEN 4 THEN 'Miércoles'
             WHEN 5 THEN 'Jueves'
             WHEN 6 THEN 'Viernes'
             WHEN 7 THEN 'Sábado'
           END
         )
         AND TIME(NOW()) BETWEEN H.hora_inicio AND H.hora_fin;
     `;

    const [horarioResult] = await db.query(sqlHorario, [codigo]);

    if (horarioResult.length === 0) {
      return res.status(404).json({ mensaje: "Estás en el edificio correcto, pero no hay clases en este salón ahora." });
    }

    const horario = horarioResult[0];

    // 6. RESPUESTA EXITOSA
    res.status(200).json({
      usuario: id_usuario,
      id_materia: horario.id_materia,
      duracion_clase: horario.duracion_minutos, // CORREGIDO: Debe llamarse 'duracion_clase'
      id_edificio: geofenceResult[0].id_edificio, // AÑADIDO: El ID del edificio para el frontend
      materia: horario.nombre_materia,
      horario: {
        dia: horario.dia,
        hora_inicio: horario.hora_inicio,
        hora_fin: horario.hora_fin
      }
    });

  } catch (error) {
    console.error("Error en POST /horario:", error);
    res.status(500).json({ error: "Error interno del servidor", detalles: error.message });
  }
});

module.exports = router;