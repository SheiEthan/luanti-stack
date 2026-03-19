# 🎮 Luanti Stack - Docker Monitoring

Un stack Docker complet pour déployer un serveur **Luanti** (fork de Minetest) avec monitoring complet via **Prometheus** et **Grafana**.

## 📋 Arborescence du projet

```
luanti-stack/
├── Dockerfile                          # Compilation de Luanti avec support Prometheus
├── docker-compose.yml                  # Orchestration des 4 services
├── nginx.conf                          # Configuration du reverse proxy
├── .dockerignore                       # Exclusions Docker
├── README.md                           # Cette documentation
├── minetest/
│   └── minetest.conf                   # Configuration du serveur Luanti
├── prometheus/
│   └── prometheus.yml                  # Configuration de Prometheus
├── grafana/
│   ├── dashboards/
│   │   └── luanti-minimal.json         # Dashboard Grafana prêt à l'emploi
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml          # Configuration de la datasource Prometheus
│       └── dashboards/
│           └── dashboards.yml          # Configuration du provisioning Grafana
└── web/
    └── index.html                      # Landing page Nginx
```

## 🚀 Démarrage rapide

### Prérequis

- Docker
- Docker Compose
- Au minimum 2GB de RAM disponible

### Installation et lancement

```bash
# Cloner le repository
git clone <repository-url>
cd luanti-stack

# Lancer les services
docker-compose up -d

# Vérifier l'état des services
docker-compose ps
```

### Accès aux services

| Service                  | URL                   | Identifiants  |
| ------------------------ | --------------------- | ------------- |
| **Landing Page (Nginx)** | http://localhost:8080 | -             |
| **Prometheus**           | http://localhost:9090 | -             |
| **Grafana**              | http://localhost:3000 | admin / admin |
| **Luanti Server**        | localhost:30000/udp   | -             |

## 📊 Services inclus

### 1. **Luanti Server** (Port UDP 30000, TCP 30000)

- ✅ Serveur de jeu multijoueur Luanti
- ✅ Métriques Prometheus expose sur `/metrics` (TCP 30000)
- ✅ Configuré pour support complet du monitoring
- ✅ Volume persistent pour les mondes de jeu

### 2. **Prometheus** (Port TCP 9090)

- ✅ Scrape automatique des métriques Luanti
- ✅ Retention des données : 72h
- ✅ Scrape interval : 10s pour Luanti, 15s pour Prometheus

### 3. **Grafana** (Port TCP 3000)

- ✅ Dashboard prêt à l'emploi : "Luanti Server Monitoring"
- ✅ Datasource Prometheus préconfiguré
- ✅ Visualisations incluses :
  - Status du serveur Luanti
  - Indicateur statut (gauge)
  - Durée de scrape Prometheus

### 4. **Nginx** (Port TCP 8080)

- ✅ Landing page de bienvenue
- ✅ Reverse proxy configuré
- ✅ GZIP compression activé
- ✅ Headers de sécurité

## ⚙️ Configuration Luanti (`minetest.conf`)

Le fichier `minetest/minetest.conf` configure les paramètres du serveur :

### Paramètres clés

```ini
# Informations serveur
server_name = Luanti Docker                        # Nom du serveur
server_description = ...                           # Description longue
motd = Bienvenue ! ...                             # Message de bienvenue

# Réseau
port = 30000                                       # Port UDP/TCP du serveur

# Prometheus Metrics
prometheus_listener_address = 0.0.0.0:30000       # Écoute les métriques sur TCP 30000
                                                  # (0.0.0.0 = accessible depuis Docker)

# Gameplay
default_game = minetest_game                      # Jeu par défaut
creative_mode = true                              # Mode créatif activé
enable_damage = false                             # Pas de dégâts de chute
max_users = 10                                    # Maximum de joueurs simultanés

# Admin
name = Sheiethan                                  # Nom du propriétaire
```

### Modification de la configuration

Pour modifier la config :

1. Édite `minetest/minetest.conf`
2. Pas besoin de rebuild Docker (volume monté en read-only dans le conteneur)
3. Relance le serveur : `docker-compose restart luanti`

## 📈 Métriques exposées

Le serveur Luanti expose les métriques standard Prometheus sur `http://luanti:30000/metrics` :

```
up{job="luanti"}                    # Statut du serveur (1=up, 0=down)
scrape_duration_seconds             # Temps de scrape Prometheus
scrape_samples_post_metric_relabeling  # Nombre de samples
```

Et potentiellement d'autres métriques spécifiques à Luanti selon sa version.

## 🔧 Configuration

### minetest.conf

Principales configurations du serveur :

```conf
server_port = 30000                 # Port UDP pour le jeu
max_users = 20                       # Maximum de joueurs simultanés
prometheus_enabled = true            # Active le endpoint /metrics
prometheus_port = 30000              # Port des métriques (TCP)
new_style_doors = true               # Support des portes modernes
enable_damage = true                 # Les dégâts sont activés
enable_pvp = false                   # PvP désactivé
```

### prometheus.yml

Scrape config pour Luanti :

```yaml
- job_name: "luanti"
  scrape_interval: 10s
  static_configs:
    - targets: ["luanti:30000"]
  metrics_path: "/metrics"
```

### Grafana Provisioning

Datasource et dashboard automatiquement configurés au démarrage :

- Datasource : http://prometheus:9090
- Dashboard : `/etc/grafana/provisioning/dashboards/`

## 🐳 Commandes Docker Compose utiles

```bash
# Démarrer les services
docker-compose up -d

# Voir les logs en temps réel
docker-compose logs -f

# Voir les logs d'un service spécifique
docker-compose logs -f luanti
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Arrêter les services
docker-compose down

# Arrêter et supprimer les volumes
docker-compose down -v

# Rebuild les images
docker-compose build --no-cache

# Vérifier le statut
docker-compose ps

# Accéder au shell d'un conteneur
docker-compose exec luanti /bin/bash
docker-compose exec grafana /bin/bash
```

## ✅ Points de contrôle - Validations

### 1. Tous les services UP

```bash
docker-compose ps
# Résultat attendu : 4 services UP
```

### 2. Prometheus scrape Luanti

- Ouvrir http://localhost:9090
- Aller dans "Status" → "Targets"
- Vérifier que "luanti" est "UP"

### 3. Vérifier une requête

- Dans Prometheus : http://localhost:9090/graph
- Query : `up{job="luanti"}`
- Vérifier que le résultat affiche `1` (UP)

### 4. Dashboard Grafana

- Ouvrir http://localhost:3000
- Se connecter : admin / admin
- Aller dans "Dashboards"
- Ouvrir "Luanti Server Monitoring"
- Vérifier les 3 panneaux :
  - ✅ Status du serveur (courbe)
  - ✅ Indicateur statut (gauge green)
  - ✅ Scrape duration (timeseries)

### 5. Landing page Nginx

- Ouvrir http://localhost:8080
- Vérifier que la page se charge
- Cliquer sur les liens vers les services

## 🛠️ Dépannage

### Le service Luanti ne démarre pas

```bash
# Vérifier les logs
docker-compose logs luanti

# Vérifier que le port n'est pas occupé
lsof -i :30000

# Reconstruire l'image
docker-compose build --no-cache luanti
```

### Prometheus ne scrape pas Luanti

1. Vérifier que Luanti est UP : `docker-compose ps`
2. Vérifier la configuration : `cat prometheus/prometheus.yml`
3. Vérifier le DNS interne Docker : `docker-compose exec prometheus ping luanti`
4. Redémarrer Prometheus : `docker-compose restart prometheus`

### Grafana ne trouve pas la datasource

1. Vérifier le démarrage de Prometheus : `docker-compose logs prometheus`
2. Vérifier la configuration datasource : `cat grafana/provisioning/datasources/datasource.yml`
3. Redémarrer Grafana : `docker-compose restart grafana`

### Les volumes persistent ne se créent pas

```bash
# Vérifier les volumes
docker volume ls

# Supprimer les volumes (attention : destruction de données)
docker-compose down -v

# Relancer
docker-compose up -d
```

## 📝 Notes importantes

⚠️ **Sécurité** :

- ✋ Les identifiants Grafana `admin / admin` ne conviennent QUE pour le développement
- 🔐 Changer le mot de passe en production
- 🔒 Configurer les règles firewall/policiales appropriées
- ⛔ Ne pas exposer Prometheus/Grafana sur internet sans authentification

⚠️ **Performance** :

- 💾 Les données Prometheus sont retenues 72h par défaut
- 📈 Ajuster `--storage.tsdb.retention.time` pour plus/moins d'historique
- 🎮 Luanti peut consommer beaucoup de CPU/RAM selon le nombre de joueurs

## 📚 Documentation additionnelle

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Luanti / Minetest Documentation](https://wiki.minetest.net/)
- [Docker Documentation](https://docs.docker.com/)

## 📄 License

Ce projet est fourni à titre d'exemple éducatif.

---

**Auteur** : Ethan
**Date** : 2026  
**Version** : 1.0.0
