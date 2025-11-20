const dotenv = require("dotenv");
dotenv.config();

const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const app = express();

// Rutas
const asistenciaRoutes = require("./routes/asistencia");
const horariosRoutes = require("./routes/horarios");
const ubicacionRoutes = require('./routes/ubicacion');
const authRoutes = require("./routes/auth");
const rutas = require("./routes/rutas");

// ✅ Middlewares (orden: cors -> bodyParser -> logger)
app.use(cors());
app.use(express.json());
app.use(morgan("dev")); // muestra todas las peticiones HTTP en consola

// ✅ Montar rutas (rutas específicas primero)
app.use("/horario", horariosRoutes);         // POST /horario
app.use("/asistencia", asistenciaRoutes);    // /asistencia/...
app.use("/ubicacion", ubicacionRoutes);      // /ubicacion/... (si existe)
app.use("/auth", authRoutes);
app.use("/api", rutas);

// Health-check simple
app.get("/health", (req, res) => res.json({ ok: true }));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Ruta no encontrada" });
});

// Error handler centralizado
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err && err.stack ? err.stack : err);
  res.status(500).json({ error: "Error interno del servidor" });
});

// Iniciar servidor
const os = require("os");
const interfaces = os.networkInterfaces();
const PORT = process.env.PORT || 3000;
const ip = Object.values(interfaces)
  .flat()
  .find((i) => i && i.family === "IPv4" && !i.internal)?.address;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Servidor disponible en: http://${ip || 'localhost'}:${PORT}`);
});