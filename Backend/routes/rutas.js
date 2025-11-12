const express = require("express");
const router = express.Router();
const db = require("../db"); // Este ya es el pool con promesas
const axios = require("axios");

// Endpoint para generar ruta óptima usando Mapbox Directions
router.post("/ruta", async (req, res) => {
  try {
    const { lat, lon, id_edificio } = req.body;

    if (!lat || !lon || !id_edificio) {
      return res.status(400).json({ error: "Faltan parámetros (lat, lon, id_edificio)" });
    }

    let edificioRows;
    // Decide si buscar por id numérico o por nombre de edificio
    if (/^\d+$/.test(String(id_edificio))) {
      // Buscar por ID entero
      const id = parseInt(id_edificio, 10);
      // CAMBIO: Se quitó .promise()
      [edificioRows] = await db.query(
        "SELECT ST_X(ST_Centroid(ubicacion)) AS lon, ST_Y(ST_Centroid(ubicacion)) AS lat FROM edificios WHERE id = ?",
        [id]
      );
    } else {
      // Buscar por nombre del edificio
      // CAMBIO: Se quitó .promise()
      [edificioRows] = await db.query(
        "SELECT ST_X(ST_Centroid(ubicacion)) AS lon, ST_Y(ST_Centroid(ubicacion)) AS lat FROM edificios WHERE nombre = ?",
        [id_edificio]
      );
    }

    if (!edificioRows[0] || edificioRows[0].lon === null || edificioRows[0].lat === null) {
      return res.status(404).json({ error: "Edificio no encontrado o sin ubicación válida" });
    }

    const destino = [edificioRows[0].lon, edificioRows[0].lat];
    const origen = [parseFloat(lon), parseFloat(lat)];

    const profile = "mapbox/walking"; // walking, driving, cycling
    const coordinates = `${origen[0]},${origen[1]};${destino[0]},${destino[1]}`;
    const accessToken = process.env.MAPBOX_TOKEN;

    const url = `https://api.mapbox.com/directions/v5/${profile}/${coordinates}?geometries=geojson&steps=true&access_token=${accessToken}`;

    // Llama a la API de Mapbox Directions
    const response = await axios.get(url);
    const data = response.data;

    if (!data.routes || data.routes.length === 0) {
      return res.status(404).json({ error: "No se encontró ruta" });
    }

    const route = data.routes[0];

    // Devuelve la ruta como GeoJSON FeatureCollection
    res.json({
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: route.geometry,
          properties: {
            distance: route.distance,
            duration: route.duration,
          },
        },
      ],
    });
  } catch (error) {
    console.error("Error generando ruta Mapbox:", error.message);
    res.status(500).json({ error: "Error generando ruta", detalles: error.message });
  }
});

module.exports = router;
