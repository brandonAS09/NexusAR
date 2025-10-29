const express = require("express");
const cors = require("cors");
const app = express();

// ✅ Middlewares
app.use(cors());
app.use(express.json());

// ✅ Importar rutas
const authRoutes = require("./routes/auth");
const rutas = require("./routes/rutas"); // ← Asegúrate que el archivo se llame rutas.js dentro de /routes

// ✅ Usar rutas
app.use("/auth", authRoutes);
app.use("/api", rutas); // aquí se define el endpoint base, por ejemplo: /api/ruta

// ✅ Iniciar servidor
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
