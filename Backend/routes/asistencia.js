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
    console.error("Error en /asistencia/entrada:", error.message || error);;
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
    console.error("Error /asistencia/salida:", error);
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
    console.error("Error /asistencia/:id_usuario/:id_materia:", error);
    return res.status(500).json({ error: "Error al calcular la asistencia." });
  }
});

// POST /asistencia/verificar_ubicacion
// Esta ruta SÍ recibe el ID del edificio y las coordenadas
router.post("/verificar_ubicacion", async (req, res) => {
  try {
    const { id_edificio, latitud, longitud } = req.body;

    if (!id_edificio || !latitud || !longitud) {
      return res.status(400).json({ error: "Faltan parámetros." });
    }

    const userLocationPoint = `POINT(${longitud} ${latitud})`;

    const sql = `
        SELECT ST_Contains(E.ubicacion, ST_GeomFromText(?, ?)) AS esta_dentro
        FROM Edificios E
        WHERE E.id = ?;
      `;

    const [result] = await db.query(sql, [userLocationPoint, 4326, id_edificio]);

    if (result.length === 0) {
      return res.status(404).json({ error: "Edificio no encontrado." });
    }

    // Devolvemos 'true' si esta_dentro es 1, o 'false' si es 0
    res.json({ dentro: result[0].esta_dentro === 1 });

  } catch (error) {
    console.error("Error en /verificar_ubicacion:", error);
    res.status(500).json({ error: "Error al verificar ubicación." });
  }
});

module.exports = router; // SOLO UNO AL FINAL