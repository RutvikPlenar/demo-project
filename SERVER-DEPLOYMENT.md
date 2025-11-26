# Server Deployment - Quick Reference

## Files Created

### Configuration Files
- **`docker-compose.prod.yml`** - Production Docker Compose configuration (no build, uses registry image)
- **`.env.registry`** - Registry configuration (update with your registry URL)
- **`server-configs/nginx-site.conf`** - Nginx config for your server
- **`build-and-push.sh`** - Script to build and push to registry

### Documentation
- **`DEPLOYMENT.md`** - Complete deployment guide with troubleshooting

## Quick Start

### 1. Configure Registry (Local)
```bash
# Edit .env.registry with your details
nano .env.registry

# Set:
# REGISTRY_URL=your-registry.example.com:5000
# IMAGE_NAME=demo-project
# IMAGE_TAG=v1.0.0
```

### 2. Build & Push (Local)
```bash
./build-and-push.sh
```

### 3. Deploy (Server)
```bash
# Copy files to server
scp docker-compose.prod.yml .env.registry user@server:/opt/laravel-demo/

# On server
cd /opt/laravel-demo
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Configure Nginx (Server)
```bash
sudo cp server-configs/nginx-site.conf /etc/nginx/sites-available/laravel-demo
sudo nano /etc/nginx/sites-available/laravel-demo  # Update server_name
sudo ln -s /etc/nginx/sites-available/laravel-demo /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Key Differences: Local vs Production

| Aspect | Local (docker-compose.yml) | Production (docker-compose.prod.yml) |
|--------|---------------------------|--------------------------------------|
| **Image Source** | Built locally (`build: .`) | Pulled from registry (`image: ...`) |
| **Nginx** | Containerized nginx included | Uses host nginx (removed) |
| **Volumes** | Full code mount | Only storage/cache |
| **Port** | 9001→80 (nginx) | 9000→9000 (PHP-FPM) |
| **Restart** | No policy | `unless-stopped` |

## What Changed in docker-compose.prod.yml

✅ **Removed:**
- `build: .` directive
- Entire `nginx` service (you have nginx on server)
- Full code volume mount

✅ **Added:**
- `image:` pointing to your registry
- `restart: unless-stopped`
- Health check for PHP-FPM
- Port exposure for PHP-FPM (9000)

✅ **Modified:**
- Volumes: Only mounts persistent data (storage, cache)
- Uses environment variables from `.env.registry`

## Testing Locally Before Server Deployment

You can test the production config locally:

```bash
# Update .env.registry with a test registry or use 'demo-project:test' as image
export REGISTRY_URL=localhost
export IMAGE_NAME=demo-project
export IMAGE_TAG=test

# Build image
docker build -t demo-project:test .

# Test production compose file
docker-compose -f docker-compose.prod.yml up

# In another terminal, configure nginx to point to localhost:9000
# Or just test PHP-FPM directly:
docker exec laravel_app php artisan list
```

## Important Notes

⚠️ **Before running on server:**
1. Update `.env.registry` with your actual registry URL
2. Update `server-configs/nginx-site.conf` with your domain name
3. Ensure storage and bootstrap/cache directories exist and are writable
4. Run `php artisan key:generate` in the container

🔒 **Security:**
- Port 9000 is exposed to host - ensure your firewall blocks external access
- Only ports 80/443 should be publicly accessible (via nginx)
- Use SSL/HTTPS in production (see nginx-site.conf comments)

📝 **See DEPLOYMENT.md for complete instructions and troubleshooting.**
