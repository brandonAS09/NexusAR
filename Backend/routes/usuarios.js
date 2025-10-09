const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/", (req, res) => {
  const sql = "SELECT * FROM Usuarios"; //Tabla de la base de datos

  console.log("🔍 Ejecutando consulta:", sql);

  db.query(sql, (err, results) => {
    if (err) {
      console.error("❌ Error en la consulta:", err);
      return res.status(500).json({ error: "Error al obtener usuarios" });
    }

    console.log("📊 Resultados creados:", results);
    console.log("📏 Cantidad de filas:", results.length);

    if (!results || results.length === 0) {
      return res.status(200).json({ mensaje: "⚠️ No hay registros en la tabla Usuarios" });
    }

    res.json(results);
  });
});

module.exports = router;
