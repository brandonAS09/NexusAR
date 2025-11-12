const express = require("express");
const router = express.Router();
const db = require("../db");

router.post("/horario", async (req, res) => {
  const { codigo, email } = req.body;

  if (!codigo || !email) {
    return res.status(400).json({ error: "Faltan datos (código o email)." });
  }

  // 1️⃣ Obtener ID del usuario
  const sqlUser = "SELECT id_usuario FROM Usuarios WHERE email = ?";
  db.query(sqlUser, [email], (err, userResult) => {
    if (err) {
      console.error("Error al obtener usuario:", err);
      return res.status(500).json({ error: "Error interno", detalles: err.message });
    }

    if (userResult.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado." });
    }

    const id_usuario = userResult[0].id_usuario;

    // 2️⃣ Obtener la materia actual según el horario
    const sqlHorario = `
      SELECT M.id AS id_materia, M.nombre AS nombre_materia, H.dia, H.hora_inicio, H.hora_fin
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

    db.query(sqlHorario, [codigo], (err, horarioResult) => {
      if (err) {
        console.error("Error al obtener horario:", err);
        return res.status(500).json({ error: "Error al obtener horario.", detalles: err.message });
      }

      if (horarioResult.length === 0) {
        return res.status(404).json({ mensaje: "No hay clases en este momento." });
      }

      const horario = horarioResult[0];

      res.status(200).json({
        usuario: id_usuario,
        id_materia: horario.id_materia,
        materia: horario.nombre_materia,
        horario: {
          dia: horario.dia,
          hora_inicio: horario.hora_inicio,
          hora_fin: horario.hora_fin
        }
      });
    });
  });
});

module.exports = router;
