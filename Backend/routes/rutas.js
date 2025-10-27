const express = require("express");
const router = express.Router();
const db = require("../db");




router.post("/ruta", (req, res) => {
    const { lat, lon, id_edificio } = req.body;


    if (!lat || !lon || !id_edificio) {
        return res.status(400).json({ error: "Faltan parámetros (lat,lon,id_edificio)" });

    }


    const sqlEdificio = `
    SELECT ST_AsText(ST_Centroid(ubicacion)) AS centro
    FROM edificios
    WHERE id= ?
    `;


    db.query(sqlEdificio, [id_edificio], (err, result) => {
        if (err) return res.status(500).json({ error: "Error al consultar edificio", detalles: err });
        if (result.length == 0) return res.status(404).json({ error: "Edificio no encontrado" });


        const coords = result[0].centro.replace("POINT(", "").replace(")", "").split(" ");

        const destino = {
            lon: parseFloat(coords[0]),
            lat: parseFloat(coords[1])
        };

        const geojsonRuta = {
            type: "FeatureCollection",
            features: [
                {
                    type: "Feature",
                    geomtry: {
                        type: "LineString",
                        coordinates: [
                            [lon, lat],
                            [destino.lon, destino.lat]
                        ]
                    },
                    properties: {
                        nombre: "Ruta hacia el edificio"
                    }
                }
            ]
        };
        res.json(geojsonRuta);
    })
})

module.exports = router;