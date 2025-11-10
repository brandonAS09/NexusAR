const express = require("express");
const cors = require("cors");
const app = express();
const asistenciaRoutes = require("./routes/asistencia");
require("dotenv").config();

// ✅ Middlewares
app.use(cors());
app.use(express.json());

// ✅ Importar rutas
const authRoutes = require("./routes/auth");
const rutas = require("./routes/rutas"); // ← Asegúrate que el archivo se llame rutas.js dentro de /routes

// ✅ Usar rutas
app.use("/auth", authRoutes);
app.use("/api", rutas); // aquí se define el endpoint base, por ejemplo: /api/ruta
app.use("/asistencia",asistenciaRoutes); //rutas de asistencia, endpoints agregados

// ✅ Iniciar servidor
const os = require("os");
const interfaces = os.networkInterfaces();
const PORT = 3000;
const ip = Object.values(interfaces)
  .flat()
  .find((i) => i.family === "IPv4" && !i.internal)?.address;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Servidor disponible en: http://${ip}:${PORT}`);
});

