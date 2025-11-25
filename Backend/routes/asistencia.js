const express = require("express");
const router = express.Router();
const db = require("../db");


async function registrarAsistenciaCompleta(id_usuario,id_materia){
  try{
    await db.query(
      `INSERT INTO asistencias_completas (id_usuario,id_materia,fecha)
      VALUES(?,?,NOW())`,
      [id_usuario,id_materia]
    )
  }catch(error){
    console.error("Error al registrar asistencia completa",error);
  }
}
async function romperRacha(id_usuario,tipo){
  const colRacha = tipo ==='puntualidad' ? 'racha_puntualidad': 'racha_asistencia';
  const colUltima = tipo ==='puntualidad' ? 'ultima_puntualidad': 'ultima_asistencia';

  try {
    const sql = `
    UPDATE LogrosRacha
    SET ${colRacha} = 0, ${colUltima} = NOW()
    WHERE id_usuario = ?
    `;

    await db.query(sql,[id_usuario]);
    console.log(`[LOGROS] Racha de ${tipo} fue reiniciada.`);
    
  }catch(error){
    console.error(`Error reiniciando racha de ${tipo}: `,error);
  }
}

// --- FUNCIÓN AUXILIAR PARA GESTIONAR RACHAS ---
async function actualizarRacha(id_usuario, tipo) {
  const colRacha = tipo === 'puntualidad' ? 'racha_puntualidad' : 'racha_asistencia';
  const colUltima = tipo === 'puntualidad' ? 'ultima_puntualidad' : 'ultima_asistencia';

  try {
    const sqlCheck = `
            SELECT ${colRacha} as racha, 
                   ${colUltima} as ultima_fecha,
                   DATEDIFF(NOW(), ${colUltima}) AS dias_pasados,
                   DAYOFWEEK(NOW()) as dia_semana_hoy -- 1=Domingo, 2=Lunes...
            FROM LogrosRacha 
            WHERE id_usuario = ?`;

    const [rows] = await db.query(sqlCheck, [id_usuario]);

    // --- CASO 1: PRIMERA VEZ ---
    if (rows.length === 0) {
      const sqlInsert = `
                INSERT INTO LogrosRacha (id_usuario, ${colRacha}, ${colUltima}) 
                VALUES (?, 1, NOW())`;
      await db.query(sqlInsert, [id_usuario]);
      console.log(`[LOGROS] Nueva racha de ${tipo} iniciada (1).`);
      return;
    }

    const { racha, dias_pasados, dia_semana_hoy } = rows[0];

    console.log(`[LOGROS DEBUG] Racha actual: ${racha}, Días pasados: ${dias_pasados}, Hoy es día: ${dia_semana_hoy}`);

    // --- CASO 2: YA REGISTRADO HOY (Anti-farm) ---
    if (dias_pasados === 0) {
      console.log(`[LOGROS] ${tipo}: Ya sumaste puntos hoy. No se actualiza.`);
      return;
    }

    let nuevaRacha = 1;

    // --- CASO 3: RACHA CONSECUTIVA ---
    if (dias_pasados === 1) {
      nuevaRacha = racha + 1;
    }
    // --- CASO 4: FIN DE SEMANA (El arreglo para que no pierdas racha el lunes) ---
    // Si hoy es Lunes (2) y pasaron 3 días (desde el Viernes) o 2 días (desde el Sábado)
    else if (dia_semana_hoy === 2 && dias_pasados <= 3) {
      console.log(`[LOGROS] ¡Salvado por el fin de semana! Mantenemos la racha.`);
      nuevaRacha = racha + 1;
    }
    else {
      console.log(`[LOGROS] Racha perdida. Días pasados: ${dias_pasados}`);
    }

    const sqlUpdate = `
            UPDATE LogrosRacha 
            SET ${colRacha} = ?, ${colUltima} = NOW() 
            WHERE id_usuario = ?`;

    await db.query(sqlUpdate, [nuevaRacha, id_usuario]);
    console.log(`[LOGROS] Racha de ${tipo} actualizada: ${racha} -> ${nuevaRacha}`);

  } catch (error) {
    console.error(`Error actualizando racha de ${tipo}:`, error);
  }
}

// ---------------------------------------------------------
// POST /asistencia/entrada 
// ---------------------------------------------------------
router.post("/entrada", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;

    if (!id_usuario || !id_materia || !timestamp) {
      return res.status(400).json({ error: "Faltan parámetros" });
    }

    // 1. REGISTRAR ENTRADA
    await db.query(
      `INSERT INTO asistencia_tiempos (id_usuario, id_materia, entrada)
       VALUES (?, ?, ?)`,
      [id_usuario, id_materia, timestamp]
    );

    // 2. VERIFICAR PUNTUALIDAD
    // Corrección: Usamos 'dia' o 'dia_semana' según lo que tengas.
    // Asegúrate de correr el SQL que te di arriba para tener 'dia_semana'.
    const sqlHorario = `
        SELECT hora_inicio 
        FROM Horarios 
        WHERE id_materia = ? 
        -- Ajuste para coincidir con MySQL (1=Domingo ... 7=Sabado)
        -- Si tu timestamp es Lunes, DAYOFWEEK da 2.
        AND dia_semana = DAYOFWEEK(?) 
        LIMIT 1
    `;

    const [horarioRows] = await db.query(sqlHorario, [id_materia, timestamp]);
    let esPuntual = false;
    let mensajeExtra = "";

    if (horarioRows.length > 0) {
      const horaInicioStr = horarioRows[0].hora_inicio;
      const fechaEntrada = new Date(timestamp);
      const fechaClase = new Date(timestamp);

      // Manejo robusto de la hora (HH:MM:SS)
      const [horas, minutos] = horaInicioStr.split(':');
      fechaClase.setHours(horas, minutos, 0, 0);

      const diferenciaMin = (fechaEntrada - fechaClase) / 1000 / 60;

      console.log(`[PUNTUALIDAD] Clase: ${horaInicioStr}, Llegada: ${fechaEntrada.toLocaleTimeString()}, Dif: ${diferenciaMin.toFixed(2)} min`);

      // Si llegó antes (dif negativa) o hasta 5 min tarde
      if (diferenciaMin <= 5) {
        esPuntual = true;
        await actualizarRacha(id_usuario, 'puntualidad');
        mensajeExtra = " ¡Puntualidad +1!";
      }else{
        console.log("[PUNTUALIDAD] Llegó tarde, rompiendo racha.");
        await romperRacha(id_usuario,'puntualidad')
      }
    } else {
      console.warn(`[ADVERTENCIA] No se encontró horario para materia ${id_materia} en esta fecha. Revisa la columna 'dia_semana'.`);
    }

    return res.status(201).json({
      mensaje: `Entrada registrada correctamente.${mensajeExtra}`,
      puntual: esPuntual
    });

  } catch (error) {
    console.error("Error en /asistencia/entrada:", error);
    // Devolvemos detalles del error SQL solo en desarrollo para que sepas qué columna falta
    return res.status(500).json({ error: "Error al registrar la entrada", sqlError: error.message });
  }
});

// ---------------------------------------------------------
// POST /asistencia/salida
// ---------------------------------------------------------
router.post("/salida", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;

    if (!id_usuario || !id_materia || !timestamp) {
      return res.status(400).json({ error: "Faltan parámetros" });
    }

    const [rows] = await db.query(
      `SELECT id FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NULL
       ORDER BY entrada DESC LIMIT 1`,
      [id_usuario, id_materia]
    );

    if (!rows || rows.length === 0) {
      return res.status(400).json({ error: "No se encontró una entrada activa." });
    }

    await db.query(
      `UPDATE asistencia_tiempos SET salida = ? WHERE id = ?`,
      [timestamp, rows[0].id]
    );

    return res.status(200).json({ mensaje: "Salida registrada correctamente" });
  } catch (error) {
    console.error("Error /asistencia/salida:", error);
    return res.status(500).json({ error: "Error al registrar la salida." });
  }
});

// ---------------------------------------------------------
// GET /asistencia/:id_usuario/:id_materia
// ---------------------------------------------------------
router.get("/:id_usuario/:id_materia", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.params;

    const [rows] = await db.query(
      `SELECT SUM(TIMESTAMPDIFF(MINUTE, entrada, salida)) AS minutos_totales
       FROM asistencia_tiempos
       WHERE id_usuario = ? AND id_materia = ? AND salida IS NOT NULL`,
      [id_usuario, id_materia]
    );

    const minutosTotales = (rows && rows[0] && rows[0].minutos_totales) ? rows[0].minutos_totales : 0;

    const [materia] = await db.query(
      `SELECT duracion_minutos FROM Materias WHERE id = ?`,
      [id_materia]
    );

    if (!materia || materia.length === 0) {
      return res.status(404).json({ error: "Materia no encontrada" });
    }

    const duracion = materia[0].duracion_minutos;
    const porcentaje = duracion && duracion > 0 ? (minutosTotales / duracion) * 100 : 0;

    if (porcentaje >= 80) {
      

      await actualizarRacha(id_usuario, 'asistencia'); // Solo aquí se suma asistencia
      await registrarAsistenciaCompleta(id_usuario,id_materia);//Helper para registrar la asistencia en la tabla de asistencias_completas en base de datos para historial de asistencias

      return res.json({
        exito: true,
        mensaje: "Tu asistencia fue registrada correctamente. ¡Punto de asistencia sumado!",
        porcentaje: Number(porcentaje.toFixed(2))
      });
    } else {
      await romperRacha(id_usuario,'asistencia')

      return res.json({
        exito: false,
        mensaje: "Tu asistencia no se registró, no permaneciste el tiempo suficiente en clase.",
        porcentaje: Number(porcentaje.toFixed(2))
      });
    }
  } catch (error) {
    console.error("Error /asistencia/:id_usuario/:id_materia:", error);
    return res.status(500).json({ error: "Error al calcular la asistencia." });
  }
});

// El endpoint de verificar_ubicacion se mantiene igual que antes...
router.post("/verificar_ubicacion", async (req, res) => {
  try {
    const { id_edificio, latitud, longitud } = req.body;

    if (!id_edificio || latitud == null || longitud == null) {
      return res.status(400).json({ error: "Faltan parámetros." });
    }

    const userLocationPoint = `POINT(${longitud} ${latitud})`;

    const sql = `
          SELECT 
            E.nombre AS nombre_edificio,
            ST_Contains(E.ubicacion, ST_GeomFromText(?, 4326)) AS esta_dentro,
            ST_Distance_Sphere(ST_Centroid(E.ubicacion), ST_GeomFromText(?, 4326)) AS distancia_metros
          FROM edificios E
          WHERE E.id = ?;
        `;

    const [result] = await db.query(sql, [userLocationPoint, userLocationPoint, id_edificio]);

    if (!result || result.length === 0) {
      return res.status(404).json({ error: "Edificio no encontrado." });
    }

    const info = result[0];
    let dentro = (info.esta_dentro === 1 || info.esta_dentro === true);
    const radius = 20;
    const distancia = info.distancia_metros != null ? Number(info.distancia_metros) : null;

    if (!dentro && distancia != null && distancia <= radius) {
      dentro = true;
    }

    if (!dentro) {
      return res.status(403).json({
        dentro: false,
        mensaje: `Estás fuera del rango.`,
        distancia_metros: distancia,
      });
    }

    return res.json({ dentro: true, distancia_metros: distancia });

  } catch (error) {
    console.error("Error en /verificar_ubicacion:", error);
    return res.status(500).json({ error: "Error al verificar ubicación." });
  }
});

module.exports = router;