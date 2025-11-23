const express = require('express');
const router = express.Router();
const db = require('../db');

router.post('/info_clase', async (req, res) => {
    const { codigo_qr } = req.body;

    if (!codigo_qr) {
        return res.status(400).json({ error: "Código QR no proporcionado" });
    }

    // Nota: He limpiado esta consulta SQL para evitar caracteres invisibles.
    // Asegúrate de que tu tabla en MariaDB tenga las columnas escritas exactamente así.
    const sql = `
        SELECT 
            m.nombre AS materia, 
            m.Semestre, 
            m.Carrera, 
            m.NombreProfesor, 
            h.Grupo, 
            s.nombre AS nombre_salon, 
            h.dia, 
            h.hora_inicio, 
            h.hora_fin
        FROM Materias m 
        INNER JOIN Horarios h ON h.id_materia = m.id 
        INNER JOIN Salones s ON s.id_salon = h.id_salon 
        WHERE s.id_salon = ? 
        AND h.dia = (
            CASE DAYOFWEEK(DATE_SUB(NOW(), INTERVAL 8 HOUR)) 
                WHEN 1 THEN 'Domingo' 
                WHEN 2 THEN 'Lunes' 
                WHEN 3 THEN 'Martes' 
                WHEN 4 THEN 'Miércoles' 
                WHEN 5 THEN 'Jueves' 
                WHEN 6 THEN 'Viernes' 
                WHEN 7 THEN 'Sábado' 
            END
        ) 
        AND TIME(DATE_SUB(NOW(), INTERVAL 8 HOUR)) BETWEEN h.hora_inicio AND h.hora_fin
        LIMIT 1;
    `;

    try {
        const [rows] = await db.query(sql, [codigo_qr]);

        if (rows.length > 0) {
            res.json({
                hay_clase: true,
                datos: rows[0]
            });
        } else {
            res.json({
                hay_clase: false,
                mensaje: "No hay clase registrada en este horario."
            });
        }
    } catch (error) {
        console.error("Error en /ar/info_clase:", error);
        // Este log te ayudará a ver si el error persiste exactamente igual
        res.status(500).json({ error: "Error interno del servidor", detalle: error.message });
    }
});

module.exports = router;