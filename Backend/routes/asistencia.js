const express = require("express");
const router = express.Router();
const db = require("../db");

// POST /asistencia/entrada
router.post("/entrada", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;

    if (!id_usuario || !id_materia || !timestamp) {
      return res.status(400).json({ error: "Faltan parámetros: id_usuario, id_materia o timestamp" });
    }

    await db.query(
      `INSERT INTO asistencia_tiempos (id_usuario, id_materia, entrada)
       VALUES (?, ?, ?)`,
      [id_usuario, id_materia, timestamp]
    );

    return res.status(201).json({ mensaje: "Entrada registrada correctamente." });
  } catch (error) {
    console.error("Error en /asistencia/entrada:", error && error.stack ? error.stack : error);
    return res.status(500).json({ error: "Error al registrar la entrada" });
  }
});

// POST /asistencia/salida
router.post("/salida", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;

    if (!id_usuario || !id_materia || !timestamp) {
      return res.status(400).json({ error: "Faltan parámetros: id_usuario, id_materia o timestamp" });
    }

    const [rows] = await db.query(
      `SELECT id FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NULL
       ORDER BY entrada DESC LIMIT 1`,
      [id_usuario, id_materia]
    );

    if (!rows || rows.length === 0) {
      return res.status(400).json({ error: "No se encontró una entrada activa." });
    }

    await db.query(
      `UPDATE asistencia_tiempos SET salida = ? WHERE id = ?`,
      [timestamp, rows[0].id]
    );

    return res.status(200).json({ mensaje: "Salida registrada correctamente" });
  } catch (error) {
    console.error("Error /asistencia/salida:", error && error.stack ? error.stack : error);
    return res.status(500).json({ error: "Error al registrar la salida." });
  }
});

// GET /asistencia/:id_usuario/:id_materia
router.get("/:id_usuario/:id_materia", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.params;

    const [rows] = await db.query(
      `SELECT SUM(TIMESTAMPDIFF(MINUTE, entrada, salida)) AS minutos_totales
       FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NOT NULL`,
      [id_usuario, id_materia]
    );

    const minutosTotales = (rows && rows[0] && rows[0].minutos_totales) ? rows[0].minutos_totales : 0;

    const [materia] = await db.query(
      `SELECT duracion_minutos FROM Materias WHERE id = ?`,
      [id_materia]
    );

    if (!materia || materia.length === 0) {
      return res.status(404).json({ error: "Materia no encontrada" });
    }

    const duracion = materia[0].duracion_minutos;
    const porcentaje = duracion && duracion > 0 ? (minutosTotales / duracion) * 100 : 0;

    if (porcentaje >= 80) {
      return res.json({
        exito: true,
        mensaje: "Tu asistencia fue registrada correctamente.",
        porcentaje: Number(porcentaje.toFixed(2))
      });
    } else {
      return res.json({
        exito: false,
        mensaje: "Tu asistencia no se registró, no permaneciste el tiempo suficiente en clase.",
        porcentaje: Number(porcentaje.toFixed(2))
      });
    }
  } catch (error) {
    console.error("Error /asistencia/:id_usuario/:id_materia:", error && error.stack ? error.stack : error);
    return res.status(500).json({ error: "Error al calcular la asistencia." });
  }
});

// POST /asistencia/verificar_ubicacion
// Body: { id_edificio, latitud, longitud }
router.post("/verificar_ubicacion", async (req, res) => {
  try {
    const { id_edificio, latitud, longitud } = req.body;

    if (!id_edificio || latitud == null || longitud == null) {
      return res.status(400).json({ error: "Faltan parámetros." });
    }

    const userLocationPoint = `POINT(${longitud} ${latitud})`;

    const sql = `
      SELECT 
        E.nombre AS nombre_edificio,
        ST_Contains(E.ubicacion, ST_GeomFromText(?, 4326)) AS esta_dentro,
        ST_Distance_Sphere(ST_Centroid(E.ubicacion), ST_GeomFromText(?, 4326)) AS distancia_metros,
        ST_SRID(E.ubicacion) AS srid,
        ST_AsText(E.ubicacion) AS wkt
      FROM edificios E
      WHERE E.id = ?;
    `;

    const [result] = await db.query(sql, [userLocationPoint, userLocationPoint, id_edificio]);

    if (!result || result.length === 0) {
      return res.status(404).json({ error: "Edificio no encontrado." });
    }

    const info = result[0];
    let dentro = (info.esta_dentro === 1 || info.esta_dentro === true);
    
    // AJUSTE: Reducimos el radio a 20 metros para que detecte "fuera" más rápido en pruebas
    const radius = 20;

    const distancia = info.distancia_metros != null ? Number(info.distancia_metros) : null;

    // Fallback por distancia
    if (!dentro) {
      if (distancia != null && distancia <= radius) {
        dentro = true;
      }
    }

    console.log(`📡 Verificación GPS: Distancia ${distancia?.toFixed(2)}m (Radio ${radius}m) -> ${dentro ? 'DENTRO ✅' : 'FUERA ❌'}`);

    // CORRECCIÓN CRÍTICA:
    // Si está fuera, devolvemos 403. Esto asegura que tu Flutter entre al bloque 'else if (resp['statusCode'] == 403)'
    if (!dentro) {
      return res.status(403).json({
        dentro: false,
        mensaje: `Estás fuera del rango (${distancia?.toFixed(1)}m > ${radius}m)`,
        distancia_metros: distancia,
        geofence_radius_m: radius
      });
    }

    return res.json({
      dentro: true,
      distancia_metros: distancia,
      geofence_radius_m: radius
    });

  } catch (error) {
    console.error("Error en /verificar_ubicacion:", error && error.stack ? error.stack : error);
    return res.status(500).json({ error: "Error al verificar ubicación." });
  }
});

module.exports = router;