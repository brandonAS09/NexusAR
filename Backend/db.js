const mysql = require("mysql2");

const db = mysql.createConnection({
    host: "remot.allan3235.com",
    port: "3306",
    user: "root",
    password: "12345",
    database: "Usuarios", // ✅ base de datos correcta
});

db.connect((err) => {
    if (err) {
        console.error("❌ Error al conectar a la base de datos:", err);
    } else {
        console.log("✅ Conexión exitosa a la base de datos");
    }
});

module.exports = db;
