const express = require("express");
const router = express.Router();
const db = require("../db");

// --- NUEVO: Obtener ID por Email (Para facilitar la integración) ---
router.get("/usuario/:email", async (req, res) => {
    try {
        const { email } = req.params;
        const sql = "SELECT id_usuario FROM Usuarios WHERE CorreoUsuario = ?";
        const [result] = await db.query(sql, [email]);

        if (result.length === 0) {
            return res.status(404).json({ error: "Usuario no encontrado" });
        }
        return res.json({ id_usuario: result[0].id_usuario });
    } catch (err) {
        console.error("Error obteniendo usuario:", err);
        return res.status(500).json({ error: "Error servidor" });
    }
});

// POST: Actualizar/Iniciar Racha
router.post("/racha", async (req, res) => {
    try {
        const { id_usuario } = req.body;

        if (!id_usuario) {
            return res.status(400).json({ error: "No se ingreso el id del usuario" });
        }

        // Verificamos si ya existe registro de racha para este usuario
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
            // Primera vez
            const sqlInsert = "INSERT INTO LogrosRacha (id_usuario, racha, ultima_racha) VALUES (?, 1, NOW())";
            const [insertResult] = await db.query(sqlInsert, [id_usuario]);

            return res.status(201).json({
                mensaje: "Primera racha iniciada correctamente",
                racha_actual: 1,
                insertResult: insertResult.insertId
            });
        } else {
            const datos = result[0];
            const diasPasados = datos.dias_pasados;
            const racha = datos.racha;

            // Si ya se actualizó hoy (dias_pasados == 0), no hacemos nada
            if (diasPasados === 0) {
                return res.status(200).json({
                    mensaje: "Racha ya actualizada hoy. ¡Sigue así!",
                    racha_actual: racha
                });
            }

            // Lógica de Racha:
            // Si pasó 1 día (ayer a hoy), sumamos 1.
            // Si pasaron más de 1 día, reiniciamos a 1.
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
        console.error("Error en /logros/racha", err);
        return res.status(500).json({ error: "Error en el servidor " });
    }
});

router.post("/rachaAsis", async (req, res) => {
    try {
        const { id_usuario } = req.body;

        if (!id_usuario) {
            return res.status(400).json({ error: "No se ingreso el id del usuario" });
        }

        // Verificamos si ya existe registro de racha para este usuario
        const sqlCheck = `
            SELECT 
                id_usuario, 
                racha_asistencia, 
                DATEDIFF(NOW(), ultima_asistencia) AS dias_pasados 
            FROM LogrosRacha 
            WHERE id_usuario = ?
        `;

        const [result] = await db.query(sqlCheck, [id_usuario]);

        if (result.length === 0) {
            // Primera vez
            const sqlInsert = "INSERT INTO LogrosRacha (id_usuario, racha_asistencia, ultima_asistencia) VALUES (?, 1, NOW())";
            const [insertResult] = await db.query(sqlInsert, [id_usuario]);

            return res.status(201).json({
                mensaje: "Primera racha de asistencia iniciada correctamente",
                racha_actual: 1,
                insertResult: insertResult.insertId
            });
        } else {
            const datos = result[0];
            const diasPasados = datos.dias_pasados;
            const racha = datos.racha;

            // Si ya se actualizó hoy (dias_pasados == 0), no hacemos nada
            if (diasPasados === 0) {
                return res.status(200).json({
                    mensaje: "Racha ya de asistencia actualizada hoy. ¡Sigue así!",
                    racha_actual: racha
                });
            }

            // Lógica de Racha:
            // Si pasó 1 día (ayer a hoy), sumamos 1.
            // Si pasaron más de 1 día, reiniciamos a 1.
            let nuevaRacha = 1;
            if (diasPasados === 1) {
                nuevaRacha = racha + 1;
            }

            const sqlUpdate = `
                UPDATE LogrosRacha 
                SET racha_asistencia = ?, ultima_asistencia = NOW() 
                WHERE id_usuario = ?
            `;

            await db.query(sqlUpdate, [nuevaRacha, id_usuario]);

            return res.status(200).json({
                mensaje: diasPasados === 1 ? "¡Racha aumentada!" : "Racha reiniciada (te extrañamos).",
                racha_actual: nuevaRacha
            });
        }

    } catch (err) {
        console.error("Error en /logros/racha", err);
        return res.status(500).json({ error: "Error en el servidor " });
    }
});

router.post("/rachaPuntu", async (req, res) => {
    try {
        const { id_usuario } = req.body;

        if (!id_usuario) {
            return res.status(400).json({ error: "No se ingreso el id del usuario" });
        }

        // Verificamos si ya existe registro de racha para este usuario
        const sqlCheck = `
            SELECT 
                id_usuario, 
                racha_puntualidad, 
                DATEDIFF(NOW(), ultima_puntualidad) AS dias_pasados 
            FROM LogrosRacha 
            WHERE id_usuario = ?
        `;

        const [result] = await db.query(sqlCheck, [id_usuario]);

        if (result.length === 0) {
            // Primera vez
            const sqlInsert = "INSERT INTO LogrosRacha (id_usuario, racha_puntualidad, ultima_puntualidad) VALUES (?, 1, NOW())";
            const [insertResult] = await db.query(sqlInsert, [id_usuario]);

            return res.status(201).json({
                mensaje: "Primera racha de puntualidad iniciada correctamente",
                racha_actual: 1,
                insertResult: insertResult.insertId
            });
        } else {
            const datos = result[0];
            const diasPasados = datos.dias_pasados;
            const racha = datos.racha;

            // Si ya se actualizó hoy (dias_pasados == 0), no hacemos nada
            if (diasPasados === 0) {
                return res.status(200).json({
                    mensaje: "Racha de puntualidad ya actualizada hoy. ¡Sigue así!",
                    racha_actual: racha
                });
            }

            // Lógica de Racha:
            // Si pasó 1 día (ayer a hoy), sumamos 1.
            // Si pasaron más de 1 día, reiniciamos a 1.
            let nuevaRacha = 1;
            if (diasPasados === 1) {
                nuevaRacha = racha + 1;
            }

            const sqlUpdate = `
                UPDATE LogrosRacha 
                SET racha_puntualidad = ?, ultima_puntualidad = NOW() 
                WHERE id_usuario = ?
            `;

            await db.query(sqlUpdate, [nuevaRacha, id_usuario]);

            return res.status(200).json({
                mensaje: diasPasados === 1 ? "¡Racha aumentada!" : "Racha reiniciada (te extrañamos).",
                racha_actual: nuevaRacha
            });
        }

    } catch (err) {
        console.error("Error en /logros/racha", err);
        return res.status(500).json({ error: "Error en el servidor " });
    }
});

// GET: Obtener Racha Actual
router.get("/obtenerRacha/:id_usuario", async (req, res) => {
    try {
        const { id_usuario } = req.params;

        if (!id_usuario) {
            return res.status(400).json({ error: "Falta el ID de estudiante" });
        }

        const sqlCheck = "SELECT racha_puntualidad, racha_asistencia FROM LogrosRacha WHERE id_usuario = ?";
        const [result] = await db.query(sqlCheck, [id_usuario]);

        if (result.length === 0) {
            return res.status(200).json({
                mensaje: "El usuario no tiene una racha activa.",
                racha_actual: 0
            });
        }

        return res.status(200).json({ racha_asistencia: result[0].racha_asistencia, racha_puntualidad: result[0].racha_puntualidad });

    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: "Error en el servidor", err });
    }
});

module.exports = router;