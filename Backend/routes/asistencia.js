const express = require("express");
const router = express.Router();
const db = require("../db");

// --- FUNCIONES AUXILIARES ---
async function registrarAsistenciaCompleta(id_usuario, id_materia) {
  try {
    await db.query(
      `INSERT INTO asistencias_completas (id_usuario, id_materia, fecha)
       VALUES (?, ?, DATE_SUB(NOW(), INTERVAL 8 HOUR))`,
      [id_usuario, id_materia]
    );
  } catch (error) {
    console.error("Error al registrar asistencia completa", error);
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

async function actualizarRacha(id_usuario, tipo) {
  const colRacha = tipo === 'puntualidad' ? 'racha_puntualidad' : 'racha_asistencia';
  const colUltima = tipo === 'puntualidad' ? 'ultima_puntualidad' : 'ultima_asistencia';

  try {
    const sqlCheck = `
            SELECT ${colRacha} as racha, 
                   ${colUltima} as ultima_fecha,
                   DATEDIFF(NOW(), ${colUltima}) AS dias_pasados,
                   DAYOFWEEK(NOW()) as dia_semana_hoy
            FROM LogrosRacha 
            WHERE id_usuario = ?`;

    const [rows] = await db.query(sqlCheck, [id_usuario]);

    if (rows.length === 0) {
      const sqlInsert = `
                INSERT INTO LogrosRacha (id_usuario, ${colRacha}, ${colUltima}) 
                VALUES (?, 1, NOW())`;
      await db.query(sqlInsert, [id_usuario]);
      console.log(`[LOGROS] Nueva racha de ${tipo} iniciada (1).`);
      return;
    }

    const { racha, dias_pasados, dia_semana_hoy } = rows[0];

    if (dias_pasados === 0) {
      console.log(`[LOGROS] ${tipo}: Ya sumaste puntos hoy. No se actualiza.`);
      return;
    }

    let nuevaRacha = 1;

    if (dias_pasados === 1) {
      nuevaRacha = racha + 1;
    }
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

// --- ENDPOINTS ---

// 1. ENTRADA
router.post("/entrada", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;
    if (!id_usuario || !id_materia || !timestamp) return res.status(400).json({ error: "Faltan parámetros" });

    await db.query(`INSERT INTO asistencia_tiempos (id_usuario, id_materia, entrada) VALUES (?, ?, ?)`, [id_usuario, id_materia, timestamp]);

    const sqlHorario = `SELECT hora_inicio FROM Horarios WHERE id_materia = ? AND dia_semana = DAYOFWEEK(?) LIMIT 1`;
    const [horarioRows] = await db.query(sqlHorario, [id_materia, timestamp]);
    let esPuntual = false;
    let mensajeExtra = "";

    if (horarioRows.length > 0) {
      const horaInicioStr = horarioRows[0].hora_inicio;
      const fechaEntrada = new Date(timestamp);
      const fechaClase = new Date(timestamp);
      const [horas, minutos] = horaInicioStr.split(':');
      fechaClase.setHours(horas, minutos, 0, 0);
      const diferenciaMin = (fechaEntrada - fechaClase) / 1000 / 60;

      if (diferenciaMin <= 5) {
        esPuntual = true;
        await actualizarRacha(id_usuario, 'puntualidad');
        mensajeExtra = " ¡Puntualidad +1!";
      } else {
        await romperRacha(id_usuario,'puntualidad')
      }
    } 
    return res.status(201).json({ mensaje: `Entrada registrada correctamente.${mensajeExtra}`, puntual: esPuntual });
  } catch (error) {
    console.error("Error en /asistencia/entrada:", error);
    return res.status(500).json({ error: "Error al registrar la entrada", sqlError: error.message });
  }
});

// 2. SALIDA
router.post("/salida", async (req, res) => {
  try {
    const { id_usuario, id_materia, timestamp } = req.body;
    if (!id_usuario || !id_materia || !timestamp) return res.status(400).json({ error: "Faltan parámetros" });

    const [rows] = await db.query(`SELECT id FROM asistencia_tiempos WHERE id_usuario = ? AND id_materia = ? AND salida IS NULL ORDER BY entrada DESC LIMIT 1`, [id_usuario, id_materia]);
    if (!rows || rows.length === 0) return res.status(400).json({ error: "No se encontró una entrada activa." });

    await db.query(`UPDATE asistencia_tiempos SET salida = ? WHERE id = ?`, [timestamp, rows[0].id]);
    return res.status(200).json({ mensaje: "Salida registrada correctamente" });
  } catch (error) {
    console.error("Error /asistencia/salida:", error);
    return res.status(500).json({ error: "Error al registrar la salida." });
  }
});

// ---------------------------------------------------------
// 3. HISTORIAL POR CORREO (NUEVO Y CORREGIDO)
// ---------------------------------------------------------
router.get("/historial/correo/:email", async (req, res) => {
    try {
        const { email } = req.params;
        const { mes, dia } = req.query;

        // 1. Buscar ID del usuario usando el CorreoUsuario
        // CAMBIO AQUÍ: 'CorreoUsuario' en lugar de 'email'
        const [users] = await db.query("SELECT id_usuario FROM Usuarios WHERE CorreoUsuario = ?", [email]);
        
        if (users.length === 0) {
            return res.status(404).json({ error: "Usuario no encontrado con ese correo." });
        }

        const id_usuario = users[0].id_usuario;

        // 2. Usar ese ID para buscar el historial
        let sql = `
            SELECT 
                m.nombre AS materia,
                DATE_FORMAT(ac.fecha, '%d/%m/%Y') AS fecha
            FROM asistencias_completas ac
            INNER JOIN Materias m ON m.id = ac.id_materia
            WHERE ac.id_usuario = ?
        `;
        
        const params = [id_usuario];

        // Filtrado opcional
        if (mes) {
            sql += " AND MONTH(ac.fecha) = ?";
            params.push(mes);
        }
        if (dia) {
            sql += " AND DAY(ac.fecha) = ?";
            params.push(dia);
        }

        sql += " ORDER BY ac.fecha DESC";

        const [rows] = await db.query(sql, params);
        res.json(rows);

    } catch (error) {
        console.error("Error obteniendo historial por correo:", error);
        res.status(500).json({ error: "Error al obtener el historial." });
    }
});

// 4. ESTADO DE ASISTENCIA (Porcentaje)
router.get("/:id_usuario/:id_materia", async (req, res) => {
  try {
    const { id_usuario, id_materia } = req.params;
    const [rows] = await db.query(`SELECT SUM(TIMESTAMPDIFF(MINUTE, entrada, salida)) AS minutos_totales FROM asistencia_tiempos WHERE id_usuario = ? AND id_materia = ? AND salida IS NOT NULL`, [id_usuario, id_materia]);
    const minutosTotales = (rows && rows[0] && rows[0].minutos_totales) ? rows[0].minutos_totales : 0;
    const [materia] = await db.query(`SELECT duracion_minutos FROM Materias WHERE id = ?`, [id_materia]);

    if (!materia || materia.length === 0) return res.status(404).json({ error: "Materia no encontrada" });

    const duracion = materia[0].duracion_minutos;
    const porcentaje = duracion && duracion > 0 ? (minutosTotales / duracion) * 100 : 0;

    if (porcentaje >= 80) {
      await actualizarRacha(id_usuario, 'asistencia'); 
      await registrarAsistenciaCompleta(id_usuario,id_materia);
      return res.json({ exito: true, mensaje: "Tu asistencia fue registrada correctamente. ¡Punto de asistencia sumado!", porcentaje: Number(porcentaje.toFixed(2)) });
    } else {
      await romperRacha(id_usuario,'asistencia')
      return res.json({ exito: false, mensaje: "Tu asistencia no se registró, no permaneciste el tiempo suficiente en clase.", porcentaje: Number(porcentaje.toFixed(2)) });
    }
  } catch (error) {
    console.error("Error /asistencia/:id_usuario/:id_materia:", error);
    return res.status(500).json({ error: "Error al calcular la asistencia." });
  }
});

// 5. VERIFICAR UBICACIÓN
router.post("/verificar_ubicacion", async (req, res) => {
  try {
    const { id_edificio, latitud, longitud } = req.body;
    if (!id_edificio || latitud == null || longitud == null) return res.status(400).json({ error: "Faltan parámetros." });

    const userLocationPoint = `POINT(${longitud} ${latitud})`;
    const sql = `SELECT E.nombre AS nombre_edificio, ST_Contains(E.ubicacion, ST_GeomFromText(?, 4326)) AS esta_dentro, ST_Distance_Sphere(ST_Centroid(E.ubicacion), ST_GeomFromText(?, 4326)) AS distancia_metros FROM edificios E WHERE E.id = ?;`;
    const [result] = await db.query(sql, [userLocationPoint, userLocationPoint, id_edificio]);

    if (!result || result.length === 0) return res.status(404).json({ error: "Edificio no encontrado." });

    const info = result[0];
    let dentro = (info.esta_dentro === 1 || info.esta_dentro === true);
    const radius = 20;
    const distancia = info.distancia_metros != null ? Number(info.distancia_metros) : null;

    if (!dentro && distancia != null && distancia <= radius) dentro = true;

    if (!dentro) return res.status(403).json({ dentro: false, mensaje: `Estás fuera del rango.`, distancia_metros: distancia });

    return res.json({ dentro: true, distancia_metros: distancia });
  } catch (error) {
    console.error("Error en /verificar_ubicacion:", error);
    return res.status(500).json({ error: "Error al verificar ubicación." });
  }
});

module.exports = router;