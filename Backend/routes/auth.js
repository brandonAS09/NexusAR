const express = require("express");
const router = express.Router();
const db = require("../db");
const bcrypt = require("bcrypt");

// Expresión regular para correos institucionales
const correoUabcRegex = /^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$/;

// Validar que la contraseña tenga 8 caracteres, mayúscula, minúscula y número
function validarContrasenia(password) {
    const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    return regex.test(password);
}

// 📩 Ruta para registrar un nuevo usuario
router.post("/register", async (req, res) => {
    const { correo, password } = req.body;

    // Validar campos vacíos
    if (!correo || !password) {
        return res.status(400).json({ error: "Ninguno de los campos debe estar vacío." });
    }

    // Validar correo institucional
    if (!correoUabcRegex.test(correo)) {
        return res.status(400).json({ error: "El correo debe ser institucional (@uabc.edu.mx)" });
    }

    // Verificar si el correo ya existe
    const sqlCheck = "SELECT * FROM Usuarios WHERE CorreoUsuario = ?";
    db.query(sqlCheck, [correo], async (err, results) => {
        if (err) {
            console.error("❌ Error en la consulta:", err);
            return res.status(500).json({ error: "Error en el servidor" });
        }

        if (results.length > 0) {
            return res.status(409).json({ error: "Este correo ya se encuentra registrado" });
        }

        // Validar formato de contraseña
        if (!validarContrasenia(password)) {
            return res.status(400).json({
                error:
                    "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número",
            });
        }

        // Encriptar contraseña
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Insertar usuario en la base de datos
        const sqlInsert = "INSERT INTO Usuarios (CorreoUsuario, Contraseña) VALUES (?, ?)";
        db.query(sqlInsert, [correo, hashedPassword], (err, results) => {
            if (err) {
                console.error("❌ Error al insertar usuario:", err);
                return res.status(500).json({ error: "Error en el servidor" });
            }

            res.json({
                mensaje: "Usuario registrado exitosamente",
                id: results.insertId,
                correo: correo,
            });
        });
    });
});

// 🔐 Ruta para iniciar sesión
router.post("/login", async (req, res) => {
    const { correo, password } = req.body;

    // Validar campos vacíos
    if (!correo || !password) {
        return res.status(400).json({ error: "Faltan datos" });
    }

    // Buscar usuario por correo
    const sql = "SELECT * FROM Usuarios WHERE CorreoUsuario = ?";
    db.query(sql, [correo], async (err, results) => {
        if (err) {
            console.error("❌ Error en la consulta:", err);
            return res.status(500).json({ error: "Error en el servidor" });
        }

        if (results.length === 0) {
            return res.status(401).json({ error: "El correo no ha sido encontrado" });
        }

        const usuario = results[0];

        // Comparar contraseñas
        const igual = await bcrypt.compare(password, usuario.Contraseña);
        if (!igual) {
            return res.status(401).json({ error: "La contraseña incorrecta" });
        }

        // Login exitoso
        res.json({
            mensaje: "Login exitoso",
            usuario: {
                id: usuario.IdUsuario,
                correo: usuario.CorreoUsuario,
            },
        });
    });
});

module.exports = router;
