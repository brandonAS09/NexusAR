# Imagen base de Node
FROM node:20

# Crear directorio de trabajo en la imagen
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del backend
COPY . .

# Exponer el puerto donde corre tu API
EXPOSE 3000

# Comando para iniciar la app
CMD ["node", "app.js"]
