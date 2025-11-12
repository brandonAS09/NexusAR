const express = require("express");
const cors = require("cors");
const app = express();
const asistenciaRoutes = require("./routes/asistencia");
const horariosRoutes = require("./routes/horarios"); // Corregido
require("dotenv").config();

// ✅ Middlewares
app.use(cors());
app.use(express.json());

// ✅ Importar rutas
const authRoutes = require("./routes/auth");
const rutas = require("./routes/rutas");
const ubicacionRoutes = require('./routes/ubicacion'); // <-- 1. LA TIENES IMPORTADA

// ✅ Usar rutas
app.use("/auth", authRoutes);
app.use("/api", rutas); 
app.use("/asistencia", asistenciaRoutes);

// --- ¡¡AQUÍ FALTA LA LÍNEA!! ---
app.use('/', ubicacionRoutes);


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
