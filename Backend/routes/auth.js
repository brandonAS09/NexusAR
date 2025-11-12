const express = require("express");
const router = express.Router();
const db = require("../db"); // Este ahora es el pool con promesas
const bcrypt = require("bcrypt");

// Expresión regular para correos institucionales
const correoUabcRegex = /^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$/;

// Validar que la contraseña tenga 8 caracteres, mayúscula, minúscula y número
function validarContrasenia(password) {
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
  return regex.test(password);
}

// Ruta para registrar un nuevo usuario (AHORA CON ASYNC/AWAIT)
router.post("/register", async (req, res) => {
  try {
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
    const [results] = await db.query(sqlCheck, [correo]);

    if (results.length > 0) {
      return res.status(409).json({ error: "Este correo ya se encuentra registrado" });
    }

    // Validar formato de contraseña
    if (!validarContrasenia(password)) {
      return res.status(400).json({
        error: "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número",
      });
    }

    // Encriptar contraseña
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insertar usuario en la base de datos
    const sqlInsert = "INSERT INTO Usuarios (CorreoUsuario, Contraseña) VALUES (?, ?)";
    const [insertResult] = await db.query(sqlInsert, [correo, hashedPassword]);

    res.status(201).json({
      mensaje: "Usuario registrado exitosamente",
      id: insertResult.insertId,
      correo: correo,
    });
  } catch (err) {
    console.error("Error en /register:", err);
    return res.status(500).json({ error: "Error en el servidor" });
  }
});

// Ruta para iniciar sesión (AHORA CON ASYNC/AWAIT)
router.post("/login", async (req, res) => {
  try {
    const { correo, password } = req.body;

    // Validar campos vacíos
    if (!correo || !password) {
      return res.status(400).json({ error: "Faltan datos" });
    }

    // Buscar usuario por correo
    const sql = "SELECT * FROM Usuarios WHERE CorreoUsuario = ?";
    const [results] = await db.query(sql, [correo]);

    if (results.length === 0) {
      return res.status(401).json({ error: "Este correo electrónico no está registrado." });
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
        id: usuario.IdUsuario, // Asegúrate que tu columna se llame 'IdUsuario'
        correo: usuario.CorreoUsuario,
      },
    });
  } catch (err) {
    console.error("Error en /login:", err);
    return res.status(500).json({ error: "Error en el servidor" });
  }
});

module.exports = router;