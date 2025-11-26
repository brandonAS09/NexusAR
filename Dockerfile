# Imagen base de Node
FROM node:20

# Crear directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json del backend
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar todo el backend
COPY . .

# Exponer el puerto 3000 (o el que uses)
EXPOSE 3000

# Arrancar la aplicación
CMD ["node", "app.js"]
