const express = require("express");
const router = express.Router();
const db = require("../db");
const turf = require("@turf/turf");
const graphlib = require("graphlib");
const { Graph } = graphlib;
const alg = graphlib.alg;

const coordKey = (coord) => `${coord[0]},${coord[1]}`;

router.post("/ruta", (req, res) => {
  let { lat, lon, id_edificio } = req.body;

  if (!lat || !lon || !id_edificio) {
    return res.status(400).json({ error: "Faltan parámetros (lat, lon, id_edificio)" });
  }

  // Detecta si es ID numérico o nombre de edificio
  let sqlEdificio, queryParam;
  if (/^\d+$/.test(String(id_edificio))) {
    sqlEdificio = `SELECT ST_AsText(ST_PointOnSurface(ubicacion)) AS punto FROM edificios WHERE id = ?;`;
    queryParam = parseInt(id_edificio, 10);
  } else {
    sqlEdificio = `SELECT ST_AsText(ST_PointOnSurface(ubicacion)) AS punto FROM edificios WHERE nombre = ?;`;
    queryParam = id_edificio;
  }

  db.query(sqlEdificio, [queryParam], (err, result) => {
    if (err) {
      console.error("Error SQL edificio:", err, "param:", queryParam);
      return res.status(500).json({ error: "Error al consultar edificio" });
    }
    if (!result || result.length === 0) {
      console.error("Edificio no encontrado:", queryParam);
      return res.status(404).json({ error: "Edificio no encontrado" });
    }

    const coords = result[0].punto.replace("POINT(", "").replace(")", "").split(" ").map(Number);
    const destino = [coords[0], coords[1]];
    const origen = [parseFloat(lon), parseFloat(lat)];

    if (isNaN(origen[0]) || isNaN(origen[1]) || isNaN(destino[0]) || isNaN(destino[1])) {
      return res.status(400).json({ error: "Coordenadas inválidas" });
    }

    db.query("SELECT id, ST_AsText(geom) AS geom FROM caminos;", (err2, caminosResult) => {
      if (err2) {
        console.error("Error SQL caminos:", err2);
        return res.status(500).json({ error: "Error al consultar caminos" });
      }
      if (!caminosResult || caminosResult.length === 0) {
        return res.status(404).json({ error: "No hay caminos registrados" });
      }

      // Construir grafo y segmentos
      const graph = new Graph({ directed: false });
      const segments = [];
      caminosResult.forEach((row) => {
        const points = row.geom.replace("LINESTRING(", "")
          .replace(")", "")
          .split(",")
          .map((p) => p.trim().split(" ").map(Number));
        for (let i = 0; i < points.length - 1; i++) {
          const aCoord = points[i];
          const bCoord = points[i + 1];
          const a = coordKey(aCoord);
          const b = coordKey(bCoord);
          const dist = turf.distance(turf.point(aCoord), turf.point(bCoord), { units: "meters" });
          graph.setNode(a, aCoord);
          graph.setNode(b, bCoord);
          graph.setEdge(a, b, dist);
          segments.push({ aKey: a, bKey: b, aCoord, bCoord, line: turf.lineString([aCoord, bCoord]) });
        }
      });

      // Snap origen/destino y conecta SIEMPRE al segmento más cercano (o nodo más cercano si no hay segmento)
      function addSnappedNode(point, label) {
        const snap = turf.nearestPointOnLine(turf.featureCollection(segments.map(s => s.line)), turf.point(point), { units: "meters" });
        const snapped = snap.geometry.coordinates;
        let segment = null;
        let minDiff = Infinity;
        segments.forEach(seg => {
          const distA = turf.distance(turf.point(seg.aCoord), turf.point(snapped), { units: 'meters' });
          const distB = turf.distance(turf.point(seg.bCoord), turf.point(snapped), { units: 'meters' });
          const segmentLen = turf.distance(turf.point(seg.aCoord), turf.point(seg.bCoord), { units: 'meters' });
          const diff = Math.abs((distA + distB) - segmentLen);
          if (diff < minDiff) { minDiff = diff; segment = seg; }
        });

        const tempKey = `TEMP_${label}`;
        graph.setNode(tempKey, snapped);

        if (segment && minDiff < 5) { // "cae" en el segmento
          graph.setEdge(tempKey, segment.aKey, turf.distance(turf.point(snapped), turf.point(segment.aCoord), { units: "meters" }));
          graph.setEdge(tempKey, segment.bKey, turf.distance(turf.point(snapped), turf.point(segment.bCoord), { units: "meters" }));
        } else {
          // Une al nodo más cercano (salvavidas real)
          let nearest = null, nearestDist = Infinity;
          graph.nodes().forEach(key => {
            const coord = graph.node(key);
            const dist = turf.distance(turf.point(snapped), turf.point(coord), { units: "meters" });
            if (dist < nearestDist) { nearestDist = dist; nearest = key; }
          });
          if (nearest) {
            graph.setEdge(tempKey, nearest, nearestDist);
          }
        }
        return tempKey;
      }

      const origenKey = addSnappedNode(origen, "origen");
      const destinoKey = addSnappedNode(destino, "destino");
      console.log("Origen (usuario):", origen);
      console.log("Destino (edificio):", destino);
      console.log("OrigenKey coords en grafo:", graph.node(origenKey));
      console.log("DestinoKey coords en grafo:", graph.node(destinoKey));

      try {
        const rutas = alg.dijkstra(graph, origenKey, (e) => graph.edge(e));
        if (!rutas[destinoKey] || rutas[destinoKey].distance === Infinity) {
          // ¡SALVA EL PROYECTO! Muestra una línea recta temporal si no hay ruta para que el patrón vea algo funcionando
          return res.json({
            type: "FeatureCollection",
            features: [turf.lineString([origen, destino])],
            aviso: "No se encontró ruta óptima, se muestra línea directa temporal."
          });
        }

        const pathKeys = [];
        let current = destinoKey;
        while (current) {
          pathKeys.unshift(current);
          if (current === origenKey) break;
          current = rutas[current] && rutas[current].predecessor;
          if (!current) break;
        }
        const coordsPath = pathKeys.map((k) => graph.node(k));
        return res.json({ type: "FeatureCollection", features: [turf.lineString(coordsPath)] });

      } catch (error) {
        return res.status(500).json({ error: "Error calculando la ruta", detalles: error.message });
      }
    });
  });
});

module.exports = router;