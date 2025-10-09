const express = require("express");
const app = express();
const PORT = 3000;
const usuariosRoutes = require("./routes/usuarios"); // importa el archivo de rutas

app.use(express.json());

// Ruta de prueba
app.get("/", (req, res) => {
  res.send("Servidor Node.js conectado con MariaDB");
});

// Usa las rutas de usuarios
app.use("/usuarios", usuariosRoutes);

app.use("/auth", require("./routes/auth")); // Asegúrate de importar las rutas de auth

// Inicia el servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
