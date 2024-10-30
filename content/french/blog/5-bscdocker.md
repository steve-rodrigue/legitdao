---
title: "Configurer un noeud Binance Smart Chain (BSC) pour LegitDAO avec Docker"
meta_title: "Configuration d'un nœud BSC pour LegitDAO avec Docker"
description: "Un guide étape par étape sur la configuration d'un nœud Binance Smart Chain (BSC) en utilisant Docker et Docker Compose pour le projet LegitDAO."
date: 2024-10-29T05:00:00Z
image: "/images/blogs/docker-bsc.jpg"
categories: ["DAO", "Dev Ops"]
author: "Pascal Germain"
tags: ["Dev Ops", "Docker"]
draft: false
---
Dans ce guide, nous allons vous montrer comment configurer et exécuter un **nœud Binance Smart Chain (BSC)** en utilisant Docker et Docker Compose. Cette configuration est spécifiquement adaptée au projet LegitDAO afin d'assurer une interaction efficace avec la blockchain, avec persistance des données, redémarrages automatiques et prise en charge des WebSockets.

Pour plus d'informations sur la manière de contribuer et de cloner LegitDAO, consultez notre [Guide pour contribuer à LegitDAO](/4-contributetolegitdao). Ce post se concentre sur la tâche spécifique d'ajout du **nœud Binance Smart Chain** au projet LegitDAO en utilisant Docker.

## Structure du projet
Voici un aperçu de la structure des dossiers pour la configuration du nœud BSC :

```plaintext
projects/infrastructure/blockchains/bsc/
├── bscdata/                  # Répertoire pour stocker les données blockchain (persistées en dehors du conteneur)
├── config/
│   └── config.toml           # Fichier de configuration du nœud BSC
├── Dockerfile                # Dockerfile pour construire le nœud BSC
├── docker-compose.yml        # Configuration de Docker Compose
└── README.md                 # Documentation du projet (ce fichier)
```

## Décomposition de la configuration

### Dockerfile
Le `Dockerfile` est le script qui construit l'image Docker pour le nœud BSC. Voici un aperçu de ses fonctionnalités :

```Dockerfile
# Utiliser une image de base officielle Go Ethereum (dernière version)
FROM ethereum/client-go:stable

# Créer un répertoire pour les données blockchain et définir les permissions
RUN mkdir -p /bscdata && chown -R 1000:1000 /bscdata

# Définir le répertoire de travail à /bsc
WORKDIR /bsc

# Copier le fichier de configuration dans le conteneur
COPY config/config.toml /bsc/config.toml

# Exposer les ports requis pour le nœud BSC
EXPOSE 8545  # Port HTTP RPC
EXPOSE 30303  # Port P2P pour la découverte de pairs
EXPOSE 8546  # Port WebSocket

# Démarrer le nœud BSC avec la configuration mise à jour
ENTRYPOINT ["geth", "--config", "/bsc/config.toml", "--datadir", "/bscdata", "--http", "--http.addr", "0.0.0.0", "--http.port", "8545", "--http.api", "eth,net,web3", "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8546", "--ws.api", "eth,net,web3", "--syncmode", "snap"]
```

**Explication** :
- **Image de base** : Utilise le client officiel Go Ethereum (`ethereum/client-go:stable`) pour exécuter le nœud BSC.
- **Persistance des données blockchain** : Le répertoire `/bscdata` dans le conteneur stocke les données blockchain.
- **Ports exposés** : Les ports pour le HTTP RPC, le P2P et les WebSockets sont exposés pour interagir avec le nœud.
- **Commande de démarrage du nœud** : Démarre le nœud BSC avec la configuration nécessaire, en exposant les endpoints HTTP et WebSocket pour les connexions des clients.

### Configuration Docker Compose

Le fichier `docker-compose.yml` définit le nœud BSC comme un service. Il mappe les ports, persiste les données et garantit que le conteneur redémarre automatiquement s'il s'arrête.

```yaml
version: '3.8'
services:
  bsc-node:
    build: .
    container_name: bsc-node
    ports:
      - "8545:8545"  # Port HTTP RPC
      - "30303:30303"  # Port P2P
      - "8546:8546"  # Port WebSocket
    volumes:
      - ./bscdata:/bscdata  # Volume externe pour persister les données blockchain
      - ./config:/bsc  # Dossier de configuration avec config.toml
    restart: always  # Redémarrer automatiquement le conteneur en cas d'arrêt
```

**Points clés** :
- **Volumes** :
  - `./bscdata:/bscdata` : Stocke les données blockchain en dehors du conteneur pour persistance.
  - `./config:/bsc` : Mappe le fichier `config.toml` local dans le conteneur pour que les modifications de configuration soient prises en compte.
- **Politique de redémarrage** : Le `restart: always` garantit que le nœud redémarre automatiquement en cas de panne.

## Installation et utilisation

### Étape 1 : Cloner le dépôt
Si ce n'est pas déjà fait, clonez le dépôt où cette configuration est hébergée :

```bash
git clone https://votre-url-de-repository/bsc-node.git
cd bsc-node
```

### Étape 2 : Mettre à jour `config.toml` (optionnel)
Vous pouvez modifier le fichier `config.toml` situé dans le répertoire `config/` pour l'adapter à vos besoins. Par défaut, la configuration se synchronise avec le réseau principal de la Binance Smart Chain et utilise le mode de synchronisation `snap` pour une synchronisation plus rapide.

Exemple de `config.toml` :

```toml
[Eth]
NetworkId = 56  # BSC Mainnet
SyncMode = "snap"  # Utilise le mode de synchronisation "snap" pour une synchronisation plus rapide
```

### Étape 3 : Construire et démarrer le nœud BSC
Utilisez Docker Compose pour construire et démarrer le nœud BSC. Cette commande va créer l'image et démarrer le conteneur :

```bash
docker-compose up --build
```

Docker Compose va :
- Construire l'image Docker.
- Démarrer le nœud BSC.
- Persister les données blockchain dans le dossier `bscdata/`.

### Étape 4 : Surveiller la progression de la synchronisation
Vous pouvez surveiller la progression de la synchronisation en vérifiant les logs. Exécutez la commande suivante pour afficher les logs :

```bash
docker logs -f bsc-node
```

Les logs montreront que le nœud recherche des pairs et se synchronise avec la Binance Smart Chain.

### Étape 5 : Interagir avec le nœud
Une fois que le nœud fonctionne, vous pouvez interagir avec lui en utilisant les commandes suivantes :

- **Obtenir le numéro de bloc actuel** :
  ```bash
  curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545
  ```

- **Se connecter via WebSocket** :
  ```bash
  ws://localhost:8546
  ```

### Étape 6 : Arrêter le nœud
Pour arrêter le nœud, appuyez sur `Ctrl + C` dans le terminal ou utilisez :

```bash
docker-compose down
```

## Dépannage

### Aucun pair trouvé
Si le nœud ne trouve pas de pairs, assurez-vous que le port `30303` est ouvert et accessible. Vérifiez également que Docker Desktop a suffisamment de ressources allouées (par exemple, CPU, mémoire).

### Synchronisation lente
Si le nœud se synchronise lentement, vous pouvez augmenter la taille du cache dans le fichier `config.toml` :

```toml
[Eth]
NetworkId = 56
SyncMode = "snap"
Cache = 4096  # Augmentez la taille du cache pour une synchronisation plus rapide
```

## Ressources supplémentaires
- [Documentation Binance Smart Chain](https://docs.bnbchain.org/)
- [Documentation Docker](https://docs.docker.com/)
- [Documentation Docker Compose](https://docs.docker.com/compose/)
