const express = require("express");
const router = express.Router();
const db = require("../db"); // tu conexión MySQL
const axios = require("axios");

// Endpoint para generar ruta óptima usando Mapbox
router.post("/ruta", async (req, res) => {
  try {
    const { lat, lon, id_edificio } = req.body;

    if (!lat || !lon || !id_edificio) {
      return res.status(400).json({ error: "Faltan parámetros (lat, lon, id_edificio)" });
    }

    // 1️⃣ Obtener coordenadas del edificio desde la base de datos
    const [edificioRows] = await db.promise().query(
      "SELECT ST_X(ubicacion) AS lon, ST_Y(ubicacion) AS lat FROM edificios WHERE id = ?",
      [id_edificio]
    );

    if (!edificioRows[0]) {
      return res.status(404).json({ error: "Edificio no encontrado" });
    }

    const destino = [edificioRows[0].lon, edificioRows[0].lat];
    const origen = [parseFloat(lon), parseFloat(lat)];

    // 2️⃣ Construir URL para Mapbox Directions API
    const profile = "mapbox/walking"; // walking, driving, cycling según preferencia
    const coordinates = `${origen[0]},${origen[1]};${destino[0]},${destino[1]}`;
    const accessToken = process.env.MAPBOX_TOKEN;

    const url = `https://api.mapbox.com/directions/v5/${profile}/${coordinates}?geometries=geojson&steps=true&access_token=${accessToken}`;

    // 3️⃣ Llamar a Mapbox Directions API
    const response = await axios.get(url);
    const data = response.data;

    if (!data.routes || data.routes.length === 0) {
      return res.status(404).json({ error: "No se encontró ruta" });
    }

    const route = data.routes[0];

    // 4️⃣ Devolver la ruta en GeoJSON para el frontend
    res.json({
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: route.geometry,
          properties: {
            distance: route.distance, // metros
            duration: route.duration, // segundos
          },
        },
      ],
    });

  } catch (error) {
    console.error("Error generando ruta Mapbox:", error.message);
    res.status(500).json({ error: "Error generando ruta" });
  }
});

module.exports = router;
