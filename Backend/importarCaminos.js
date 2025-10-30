const fs = require("fs");
const db = require("./db"); // tu archivo de conexión MySQL

// Cargar el archivo GeoJSON
const geojson = JSON.parse(fs.readFileSync("caminos.geojson", "utf8"));

geojson.features.forEach((feature, index) => {
  const nombre = feature.properties?.nombre || `Camino_${index + 1}`;

  if (feature.geometry.type !== "LineString") {
    console.warn(`⚠️  El feature ${nombre} no es un LineString, se omite.`);
    return;
  }

  // Convertir coordenadas del GeoJSON a formato WKT
  const coords = feature.geometry.coordinates
    .map(coord => `${coord[0]} ${coord[1]}`)
    .join(", ");
  const wkt = `LINESTRING(${coords})`;

  const sql = `
    INSERT INTO caminos (nombre, geom)
    VALUES (?, ST_GeomFromText(?, 4326))
  `;

  db.query(sql, [nombre, wkt], (err) => {
    if (err) {
      console.error(`❌ Error al insertar ${nombre}:`, err.message);
    } else {
      console.log(`✅ Camino "${nombre}" insertado correctamente.`);
    }
  });
});
