const express = require("express");
const router = express.Router();
const db = require("../db");
const bcrypt = require("bcrypt");


const correoUabcRegex = /^[a-zA-Z0-9._%+-]+@uabc\.edu\.mx$/;

//Funcion para validar contraseña, solamente se permiten contraseñas con al menos
//8 catacteres, una mayuscula, una minuscula y un numero
function validarContrasenia(password) {
    const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    return regex.test(password);
}



//register
//aqui se esta creando otra ruta para el register 

router.post("/register", async (req, res) => {
    const { nombre, correo, password} = req.body

    
        //validar que ningun campo este vacio
        if (!nombre || !correo || !password) {
            return res.status(400).json({ error: "Ninguno de los campos debe estar vacío." });
    
        }
    
   
    if (!correoUabcRegex.test(correo)) {
        return res.status(400).json({ error: "El correo debe ser institucional (@uabc.edu.mx)" });
    }
    
    //
    const sqlCheck = "SELECT * FROM Usuarios WHERE correo = ?"
    db.query(sqlCheck, [correo], async (err, results) => {
        if (err) {
            return res.status(500).json({ error: "Error en el servidor" });
        }
        //El correo ya esta registrado
        if (results.length > 0) {
            return res.status(409).json({ error: "Este correo ya se encuentra registrado" });
        }





        if (!validarContrasenia(password)) {
            return res.status(400).json({ error: "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número" });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);


        const sqlInsert = "INSERT INTO Usuarios (nombre, correo, password=) VALUES (?,?,?)"
        db.query(sqlInsert, [nombre, correo, hashedPassword], (err, results) => {
            if (err) {
                return res.status(500).json({ error: "Error en el servidor" });

            }
            res.json({ mensaje: "Usuario registrado exitosamente", id: results.insertId });
        });



    });
});


//login

//el router es un manejador de rutas, en este caso se esta creando una ruta para el login

router.post("/login", async (req, res) => {
    const { correo, password } = req.body;

    //Si se ingresan datos nulos

    if (!correo || !password) {
        return res.status(400).json({ error: " Faltan datos" });
    }

    //Query para encontrar similitudes entre el correo ingresado y los correos que se encuentran en la base de datos

    const sql = "SELECT * FROM Usuarios WHERE correo = ?";
    db.query(sql, [correo], async (err, results) => {
        if (err) {
            return res.status(500).json({ error: "Error en el servidor" });
        }
        if (results.length === 0) {
            return res.status(401).json({ error: "El correo no ha sido encontrado" });
        }

        //el usuario ha sido encontrado y se crea una variable constante 
        // que almacenara el resultado de haber encontrado el correo.
        const usuario = results[0];

        const igual = await bcrypt.compare(password, usuario.password);
        if (!igual) {
            return res.status(401).json({ error: "Contraseña incorrecta" });
        }
        res.json({ mensaje: "Login exitoso", usuario: { id: usuario.id, nombre: usuario.nombre, correo: usuario.correo } })
    })
})

module.exports = router;