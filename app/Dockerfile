# Utilise une image de base Node.js légère
FROM node:20-alpine
# Définit le répertoire de travail dans le conteneur
WORKDIR /app
# Copie les fichiers de configuration et d'installation
COPY package*.json ./
# Installe les dépendances de l'application
RUN npm install
# Copie le reste des fichiers de l'application dans le conteneur
COPY . .
# Expose le port sur lequel l'application écoute
EXPOSE 3000
# Commande pour démarrer l'application
CMD ["npm", "start"]
