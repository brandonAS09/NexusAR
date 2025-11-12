const express = require("express");
const router = express.Router();
const db = require("../db");

// Registrar entrada
router.post("/entrada", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.body;

    if (!id_usuario || !id_materia) {
      return res.status(400).json({ error: "Faltan datos (id_usuario o id_materia)." });
    }

    await db.query(
      `INSERT INTO asistencia_tiempos (id_usuario, id_materia, entrada)
       VALUES (?, ?, NOW())`,
      [id_usuario, id_materia]
    );

    res.json({ mensaje: "Entrada registrada correctamente." });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al registrar la entrada." });
  }
});

// Registrar salida
router.post("/salida", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.body;

    const [rows] = await db.query(
      `SELECT id FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NULL
       ORDER BY entrada DESC LIMIT 1`,
      [id_usuario, id_materia]
    );

    if (rows.length === 0) {
      return res.status(400).json({ error: "No se encontró una entrada activa." });
    }

    await db.query(
      `UPDATE asistencia_tiempos SET salida = NOW() WHERE id = ?`,
      [rows[0].id]
    );

    res.status(200).json({ mensaje: "Salida registrada correctamente." });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al registrar la salida." });
  }
});

// Calcular porcentaje de asistencia
router.get("/:id_usuario/:id_materia", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.params;

    const [rows] = await db.query(
      `SELECT SUM(TIMESTAMPDIFF(MINUTE, entrada, salida)) AS minutos_totales
       FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NOT NULL`,
      [id_usuario, id_materia]
    );

    const minutosTotales = rows[0].minutos_totales || 0;

    const [materia] = await db.query(
      `SELECT duracion_minutos FROM Materias WHERE id = ?`,
      [id_materia]
    );

    if (materia.length === 0) {
      return res.status(404).json({ error: "Materia no encontrada." });
    }

    const duracion = materia[0].duracion_minutos;
    const porcentaje = (minutosTotales / duracion) * 100;

    if (porcentaje >= 80) {
      res.json({
        exito: true,
        mensaje: "Tu asistencia fue registrada correctamente.",
        porcentaje: porcentaje.toFixed(2)
      });
    } else {
      res.json({
        exito: false,
        mensaje: "Tu asistencia no se registró, no permaneciste el tiempo suficiente.",
        porcentaje: porcentaje.toFixed(2)
      });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al calcular la asistencia." });
  }
});

module.exports = router;
