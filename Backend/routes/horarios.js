const express = require("express");
const router = express.Router();
const db = require("../db");

/**
 * POST /horario
 * Body: { codigo, email, latitud, longitud }
 * - 'codigo' puede ser id_salon (número) o qr_code (string)
 */
router.post("/", async (req, res) => {
  const { codigo, email, latitud, longitud } = req.body;

  if (!codigo || !email || latitud == null || longitud == null) {
    return res.status(400).json({ error: "Faltan datos (código, email o ubicación)." });
  }

  // ---------------------------------------------------------
  // 🕒 CALCULO DE HORA LOCAL (Timezone Fix)
  // ---------------------------------------------------------
  // Forzamos la zona horaria a 'America/Tijuana' (para UABC)
  // Esto evita que si el servidor está en UTC, falle la consulta.
  const timeZone = 'America/Tijuana';
  const now = new Date();

  // 1. Obtener hora actual en formato HH:MM:SS
  const horaActual = new Intl.DateTimeFormat('en-US', {
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false, timeZone
  }).format(now);

  // 2. Obtener día de la semana (ej: 'miércoles')
  let diaNombre = new Intl.DateTimeFormat('es-MX', { weekday: 'long', timeZone }).format(now);
  // Capitalizar primera letra: 'miércoles' -> 'Miércoles'
  diaNombre = diaNombre.charAt(0).toUpperCase() + diaNombre.slice(1);

  console.log(`📍 Petición /horario recibida. User: ${email}, Salón: ${codigo}`);
  console.log(`🕒 Hora Local Calculada (Tijuana): [${diaNombre} - ${horaActual}]`);

  try {
    // 1) Obtener id del usuario
    const [userResult] = await db.query(
      "SELECT id_usuario FROM Usuarios WHERE CorreoUsuario = ?",
      [email]
    );
    if (!userResult || userResult.length === 0) {
      console.log("Usuario no encontrado para email:", email);
      return res.status(404).json({ error: "Usuario no encontrado." });
    }
    const id_usuario = userResult[0].id_usuario;

    // Normalizamos 'codigo'
    const codigoNum = /^[0-9]+$/.test(String(codigo)) ? Number(codigo) : null;

    // 2) Verificación geoespacial
    const userLocationPoint = `POINT(${longitud} ${latitud})`;

    const sqlGeofence = `
      SELECT 
        E.id AS id_edificio,
        E.nombre AS nombre_edificio,
        S.id_salon AS id_salon,
        S.qr_code AS qr_code,
        ST_Contains(E.ubicacion, ST_GeomFromText(?, 4326)) AS esta_dentro,
        ST_Distance_Sphere(ST_Centroid(E.ubicacion), ST_GeomFromText(?, 4326)) AS distancia_metros,
        ST_SRID(E.ubicacion) AS srid,
        ST_AsText(E.ubicacion) AS wkt_ubicacion
      FROM Salones S
      JOIN edificios E ON S.id_edificio = E.id
      WHERE ${codigoNum !== null ? "S.id_salon = ? OR S.qr_code = ?" : "S.qr_code = ?"}
      LIMIT 1;
    `;

    const params = codigoNum !== null ? [userLocationPoint, userLocationPoint, codigoNum, String(codigo)] : [userLocationPoint, userLocationPoint, String(codigo)];
    const [geofenceResult] = await db.query(sqlGeofence, params);

    if (!geofenceResult || geofenceResult.length === 0) {
      console.log("No se encontró salón o edificio para código:", codigo);
      return res.status(404).json({ error: "Salón no encontrado o no tiene edificio asignado." });
    }

    const geoinfo = geofenceResult[0];
    // console.log("DEBUG geoinfo:", JSON.stringify(geoinfo));

    let esta_dentro = (geoinfo.esta_dentro === 1 || geoinfo.esta_dentro === true);
    const radius = 50; 

    if (!esta_dentro) {
      const distancia = geoinfo.distancia_metros != null ? Number(geoinfo.distancia_metros) : null;
      if (distancia != null && distancia <= radius) {
        esta_dentro = true;
      }
    }

    if (!esta_dentro) {
      return res.status(403).json({
        error: `Acceso denegado. Debes estar dentro del edificio '${geoinfo.nombre_edificio}'.`,
        detalle: {
          distancia_metros: geoinfo.distancia_metros,
          radius_used_m: radius
        }
      });
    }

    // 3) Buscar horario usando la HORA CALCULADA EN JS (NO la de la BD)
    const idSalonReal = geoinfo.id_salon;
    console.log("🔎 Buscando horario para salón:", idSalonReal, "Día:", diaNombre, "Hora >", horaActual);

    // Buscamos coincidencias directas por nombre del día
    const sqlHorario = `
      SELECT 
        H.id_horario,
        H.id_salon,
        H.id_materia,
        M.nombre AS nombre_materia,
        M.duracion_minutos AS duracion_minutos,
        H.dia,
        H.hora_inicio,
        H.hora_fin,
        IF(? >= H.hora_inicio, 'en_curso', 'proxima') as estado_clase
      FROM Horarios H
      JOIN Materias M ON H.id_materia = M.id
      WHERE H.id_salon = ?
        AND H.dia = ? 
        AND H.hora_fin > ?
      ORDER BY H.hora_inicio ASC
      LIMIT 1;
    `;
    
    // Pasamos [horaActual, idSalon, diaNombre, horaActual]
    const [horarioResult] = await db.query(sqlHorario, [horaActual, idSalonReal, diaNombre, horaActual]);

    console.log("DEBUG horarioResult raw:", JSON.stringify(horarioResult));

    if (!horarioResult || horarioResult.length === 0) {
      console.log(`❌ No se encontraron clases para ${diaNombre} después de las ${horaActual}`);
      return res.status(404).json({ mensaje: `No hay más clases programadas para hoy (${diaNombre}) en este salón.` });
    }

    const horario = horarioResult[0];
    console.log(`✅ Clase encontrada: ${horario.nombre_materia} (${horario.hora_inicio} - ${horario.hora_fin})`);

    let duracion = horario.duracion_minutos;
    if (duracion == null) {
      const [mat] = await db.query('SELECT duracion_minutos FROM Materias WHERE id = ?', [horario.id_materia]);
      if (mat && mat.length > 0) {
        duracion = mat[0].duracion_minutos;
      }
    }

    return res.status(200).json({
      usuario: id_usuario,
      id_materia: horario.id_materia,
      duracion_clase: duracion || 60,
      id_edificio: geoinfo.id_edificio || 0,
      id_salon: idSalonReal,
      materia: horario.nombre_materia,
      estado: horario.estado_clase,
      horario: {
        dia: horario.dia,
        hora_inicio: horario.hora_inicio,
        hora_fin: horario.hora_fin
      },
      debug: {
        tiempo_servidor_usado: {
          dia: diaNombre,
          hora: horaActual,
          timezone: timeZone
        }
      }
    });

  } catch (error) {
    console.error("Error en POST /horario:", error && error.stack ? error.stack : error);
    return res.status(500).json({ error: "Error interno del servidor", detalles: error && error.message ? error.message : error });
  }
});

module.exports = router;