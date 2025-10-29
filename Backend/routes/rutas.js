const express = require("express");
const router = express.Router();
const db = require("../db");
const turf = require("@turf/turf");

/**
 * Ruta POST /ruta
 * Calcula la ruta óptima desde la ubicación del usuario hasta el edificio seleccionado.
 * Requiere en el cuerpo del request: { lat, lon, id_edificio }
 */
router.post("/ruta", (req, res) => {
  const { lat, lon, id_edificio } = req.body;

  // 🔹 1️⃣ Validar parámetros
  if (!lat || !lon || !id_edificio) {
    return res.status(400).json({ error: "Faltan parámetros (lat, lon, id_edificio)" });
  }

  // 🔹 2️⃣ Consultar el centro del edificio destino
  const sqlEdificio = `
    SELECT ST_AsText(ST_Centroid(ubicacion)) AS centro
    FROM edificios
    WHERE id = ?;
  `;

  db.query(sqlEdificio, [id_edificio], (err, result) => {
    if (err) {
      console.error("❌ Error al consultar edificio:", err);
      return res.status(500).json({ error: "Error al consultar edificio", detalles: err });
    }

    if (result.length === 0) {
      return res.status(404).json({ error: "Edificio no encontrado" });
    }

    // 🔹 3️⃣ Convertir el resultado POINT(x y) → coordenadas [lon, lat]
    const coords = result[0].centro.replace("POINT(", "").replace(")", "").split(" ");
    const destino = [parseFloat(coords[0]), parseFloat(coords[1])];
    const origen = [parseFloat(lon), parseFloat(lat)];

    // 🔹 4️⃣ Consultar todos los caminos registrados en la base de datos
    const sqlCaminos = `SELECT id, ST_AsText(geom) AS geom FROM caminos;`;

    db.query(sqlCaminos, (err, caminosResult) => {
      if (err) {
        console.error("❌ Error al consultar caminos:", err);
        return res.status(500).json({ error: "Error al consultar caminos", detalles: err });
      }

      if (caminosResult.length === 0) {
        return res.status(404).json({ error: "No hay caminos registrados" });
      }

      // 🔹 5️⃣ Convertir cada registro en un Feature LineString para Turf.js
      const features = caminosResult.map(row => {
        const points = row.geom
          .replace("LINESTRING(", "")
          .replace(")", "")
          .split(",")
          .map(p => p.trim().split(" ").map(Number));

        return turf.lineString(points, { id: row.id });
      });

      // Crear una FeatureCollection con todos los caminos del campus
      const redCaminos = turf.featureCollection(features);

      try {
        // 🔹 6️⃣ Calcular la ruta más corta dentro de la red de caminos
        // (Simula la búsqueda del trayecto óptimo)
        const ruta = turf.shortestPath(
          turf.point(origen),
          turf.point(destino),
          { features: redCaminos.features }
        );

        if (!ruta) {
          return res.status(404).json({ error: "No se encontró una ruta entre los puntos." });
        }

        // 🔹 7️⃣ Devolver la ruta en formato GeoJSON
        res.json({
          type: "FeatureCollection",
          features: [ruta],
        });
      } catch (error) {
        console.error("❌ Error al calcular la ruta:", error);
        res.status(500).json({ error: "Error al calcular la ruta", detalles: error.message });
      }
    });
  });
});

module.exports = router;
