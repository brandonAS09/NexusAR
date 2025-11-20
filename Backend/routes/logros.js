const express = require("express");
const router = express.Router();
const db = require("../db");



router.post("/racha", async (req, res) => {
    try {
        const { id_usuario } = req.body;

        if (!id_usuario) {
            return res.status(400).json({ error: "No se ingreso el id del usuario" });
        }

        const sqlCheck = `
            SELECT 
                id_usuario, 
                racha, 
                DATEDIFF(NOW(), ultima_racha) AS dias_pasados 
            FROM LogrosRacha 
            WHERE id_usuario = ?
        `;

        const [result] = await db.query(sqlCheck, [id_usuario]);

        if (result.length === 0) {
            const sqlInsert = "INSERT INTO LogrosRacha (id_usuario, racha,ultima_racha) VALUES (?,1,NOW())"

            const [insertResult] = await db.query(sqlInsert, [id_usuario]);

            return res.status(201).json({
                mensaje: "Primera racha iniciada correctamente",
                racha_actual: 1,
                insertResult: insertResult.insertId
            });
        }
        else {
            const datos = result[0];
            const diasPasados = datos.dias_pasados;
            const racha = datos.racha;

            if (diasPasados === 0) {
                return res.status(200).json({
                    mensaje: "Racha ya actualizada hoy. ¡Sigue así!",
                    racha_actual: racha
                });
            }

            let nuevaRacha = 1;
            if (diasPasados === 1) {
                nuevaRacha = racha + 1;
            }

            const sqlUpdate = `
                UPDATE LogrosRacha 
                SET racha = ?, ultima_racha = NOW() 
                WHERE id_usuario = ?
            `;

            await db.query(sqlUpdate, [nuevaRacha, id_usuario]);

            return res.status(200).json({
                mensaje: diasPasados === 1 ? "¡Racha aumentada!" : "Racha reiniciada (te extrañamos).",
                racha_actual: nuevaRacha
            });
        }

    } catch (err) {
        console.error("Error en /logros", err);
        return res.status(500).json({ error: "Error en el servidor " });
    }
})


router.get("/obtenerRacha/:id_usuario", async (req, res) => {
    try {
        const { id_usuario } = req.params;

        if (!id_usuario) {
            return res.status(400).json({ error: "Falta el ID de estudiante" });
        }

        const sqlCheck = "SELECT racha FROM LogrosRacha WHERE id_usuario = ?";

        const [result] = await db.query(sqlCheck, [id_usuario]);

        if (result.length === 0) {
            return res.status(200).json({
                mensaje: "El usuario no tiene una racha activa.",
                racha_actual: 0
            });
        }

        return res.status(200).json({ racha_actual: result[0].racha });

    }catch(err){
        console.error(err);
        return res.status(500).json({error: "Error en el servidor",err});
    }
})

module.exports = router;