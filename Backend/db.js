// db.js (CORREGIDO)
const mysql = require('mysql2/promise'); // 1. CAMBIO: Importamos la versión 'promise'

// 2. CAMBIO: Usamos createPool en lugar de createConnection
const pool = mysql.createPool({
    host: "remot.allan3235.com",
    port: "3306",
    user: "teds",
    password: "123456789",
    database: "Usuarios",
    waitForConnections: true,
    connectionLimit: 10, // Límite de conexiones
    queueLimit: 0
});

// 3. CAMBIO: Hacemos una prueba de conexión (opcional pero recomendado)
pool.getConnection()
    .then(connection => {
        console.log('✅ Conexión exitosa a la base de datos (Pool)');
        connection.release(); // Liberamos la conexión de vuelta al pool
    })
    .catch(err => {
        console.error('❌ Error al conectar al pool de la base de datos:', err);
    });

// 4. CAMBIO: Exportamos el 'pool'
module.exports = pool;