# Containerized Deployment - Correct Setup

## Overview

**Everything runs in Docker containers** - no code on host filesystem needed.

```
┌─────────────────────────────────────────────┐
│ Your Server                                 │
│                                             │
│  Port 7001 ← External Access                │
│      │                                       │
│  ┌───▼──────────────────────────────────┐  │
│  │ Docker Network: demo-project         │  │
│  │                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │ nginx        │  │ app          │ │  │
│  │  │ container    │──│ container    │ │  │
│  │  │ :80          │  │ :9000        │ │  │
│  │  │              │  │ PHP-FPM      │ │  │
│  │  │              │  │ + Cron       │ │  │
│  │  │              │  │ + Laravel    │ │  │
│  │  └──────────────┘  └──────────────┘ │  │
│  │        │                   │         │  │
│  │        └─ volumes_from ────┘         │  │
│  │    (nginx reads app files)           │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

## Key Points

✅ **All code is IN the Docker image** (built and pushed to registry)
✅ **Nginx is also containerized** (not using host nginx)
✅ **No files mounted from host** (except nginx config)
✅ **Nginx accesses app files via `volumes_from`**

## Deployment Steps on Server

### 1. Create deployment directory
```bash
mkdir -p /var/www/demo-project/docker/nginx
cd /var/www/demo-project
```

### 2. Copy only configuration files
```bash
# Copy from your local machine:
scp docker-compose.prod.yml ubuntu@server:/var/www/demo-project/
scp docker/nginx/default.conf ubuntu@server:/var/www/demo-project/docker/nginx/
```

### 3. Pull and start containers
```bash
cd /var/www/demo-project
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Check status
```bash
docker-compose -f docker-compose.prod.yml ps
# Should show both containers running:
# - demo-project (app)
# - demo-project-nginx

docker-compose -f docker-compose.prod.yml logs -f
```

### 5. Access your application
```bash
# Test locally on server
curl http://localhost:7001

# Test from outside (if firewall allows)
curl http://demo1.plenar-nuc1.v6.rocks:7001
```

## What's on the Server

```
/var/www/demo-project/
├── docker-compose.prod.yml     ← Only this
└── docker/
    └── nginx/
        └── default.conf        ← And this
```

**That's it!** No `public/`, no `storage/`, no Laravel code - it's ALL in the container image.

## How It Works

1. **Docker image** contains:
   - All Laravel code
   - PHP-FPM configured
   - Cron configured
   - Dependencies installed

2. **nginx container**:
   - Uses `volumes_from: app` to access files
   - Serves static files from app container
   - Proxies PHP requests to app container

3. **Only config mounted from host**:
   - `./docker/nginx/default.conf` for nginx config

## Accessing the Application

### Option 1: Direct Access (Current Setup)
```
http://demo1.plenar-nuc1.v6.rocks:7001
```

Container nginx is exposed on port 7001.

### Option 2: Use Host Nginx as Reverse Proxy (Optional)

If you want to use your existing server nginx:

**Server nginx config:**
```nginx
server {
    listen 80;
    server_name demo1.plenar-nuc1.v6.rocks;
    
    location / {
        proxy_pass http://localhost:7001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then access via:
```
http://demo1.plenar-nuc1.v6.rocks
```

## Updating the Application

```bash
# 1. On local machine: Build new version
./build-and-push.sh

# 2. On server: Pull and restart
cd /var/www/demo-project
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# That's it! New code is deployed.
```

## Verifying Cron

```bash
# Wait 2-3 minutes, then check:
docker exec demo-project cat storage/logs/cron-test.log

# Should show entries every minute
```

## Troubleshooting

### Check containers are running
```bash
docker ps | grep demo-project
# Should show 2 containers: demo-project and demo-project-nginx
```

### Check logs
```bash
# App logs
docker logs demo-project

# Nginx logs
docker logs demo-project-nginx

# Both together
docker-compose -f docker-compose.prod.yml logs -f
```

### Test nginx can reach app
```bash
docker exec demo-project-nginx ping demo-project
# Should be able to ping
```

### Test PHP-FPM
```bash
docker exec demo-project ps aux | grep php-fpm
# Should show php-fpm processes
```

### Access container
```bash
# Access app container
docker exec -it demo-project bash

# Check files are there
ls -la /var/www/demo-project/
ls -la /var/www/demo-project/public/

# Test artisan
php artisan list
```

## Summary

- ✅ **No host nginx needed** - nginx runs in container
- ✅ **No files on host** - everything in Docker image
- ✅ **Easy updates** - just pull new image
- ✅ **Portable** - same setup works anywhere
- ✅ **Cron works** - runs inside app container

Access your app at: **http://demo1.plenar-nuc1.v6.rocks:7001**
