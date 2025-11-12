const express = require("express");
const router = express.Router();
const db = require("../db");

/**
 * 📍 ENDPOINT: /horario (Versión actualizada)
 */
router.post("/horario", async (req, res) => {
  try {
    const { codigo, email } = req.body;

    if (!codigo || !email) {
      return res.status(400).json({ error: "Faltan parámetros: codigo o email" });
    }

    // 1. Obtener el ID del usuario
    const [userRows] = await db.query(
      "SELECT id_usuario FROM Usuarios WHERE CorreoUsuario = ?",
      [email]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    const idUsuario = userRows[0].id_usuario;

    // 2. Obtener el id_salon del QR
    const idSalon = parseInt(codigo.trim(), 10);
    if (isNaN(idSalon)) {
      return res.status(400).json({ error: "El código del salón no es un número válido" });
    }

    // 3. Obtener el nombre del día de la semana
    const dias = ["Domingo", "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sábado"];
    const diaNombre = dias[new Date().getDay()];

    // 4. Obtener hora actual (formato "HH:MM:SS")
    const horaAhora = new Date().toTimeString().split(" ")[0];

    // 5. Buscar en la tabla 'Horarios'
    const sql = `
      SELECT id_materia, hora_fin
      FROM Horarios 
      WHERE id_salon = ? 
        AND dia = ?
        AND ? BETWEEN hora_inicio AND hora_fin
      LIMIT 1
    `;

    const [horarioRows] = await db.query(sql, [idSalon, diaNombre, horaAhora]);

    if (horarioRows.length === 0) {
      return res.status(404).json({
        error: "No se encontró una clase activa en este salón, a esta hora y en este día."
      });
    }

    // 6. Éxito
    res.json({
      id_materia: horarioRows[0].id_materia,
      usuario: idUsuario,
      horario: {
        hora_fin: horarioRows[0].hora_fin
      }
    });

  } catch (error) {
    console.error("Error en /horario:", error);
    return res.status(500).json({ error: "Error en el servidor" });
  }
});

/**
 * 🗺️ ENDPOINT: /ubicacion/verificar
 */
router.post("/ubicacion/verificar", async (req, res) => {
  try {
    const { lat, lon } = req.body;

    if (!lat || !lon) {
      return res.status(400).json({ error: "Faltan parámetros: lat o lon" });
    }

    const pointWKT = `POINT(${lon} ${lat})`;

    const sqlCheck = `
      SELECT COUNT(*) AS count
      FROM edificios
      WHERE ST_Contains(ubicacion, ST_GeomFromText(?))
    `;

    const [rows] = await db.query(sqlCheck, [pointWKT]);
    const dentro = rows[0].count > 0;

    res.json({ dentro });

  } catch (error) {
    console.error("Error en /ubicacion/verificar:", error);
    return res.status(500).json({ error: "Error en el servidor" });
  }
});

module.exports = router;
