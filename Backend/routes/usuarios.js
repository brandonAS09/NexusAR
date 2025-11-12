const express = require("express");
const router = express.Router();
const db = require("../db"); // Este es el pool con promesas

// CAMBIO: Se convirtió la ruta en 'async'
router.get("/", async (req, res) => {
  const sql = "SELECT * FROM Usuarios"; // Tabla de la base de datos

  console.log("🔍 Ejecutando consulta:", sql);

  // CAMBIO: Se usa 'try...catch' para manejar errores
  try {
    // CAMBIO: Se usa 'await' y se desestructura el resultado [results]
    const [results] = await db.query(sql);

    console.log("📊 Resultados creados:", results);
    console.log("📏 Cantidad de filas:", results.length);

    if (!results || results.length === 0) {
      return res.status(200).json({ mensaje: "⚠️ No hay registros en la tabla Usuarios" });
    }

    res.json(results);
  } catch (err) {
    // CAMBIO: El 'catch' maneja los errores de la consulta
    console.error("❌ Error en la consulta:", err);
    return res.status(500).json({ error: "Error al obtener usuarios" });
  }
});

module.exports = router;
