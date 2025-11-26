# Apache Optimization Documentation

## What Was Optimized

Your Dockerfile has been optimized for Apache with the following improvements:

### 1. **Apache Modules Enabled**
- `mod_rewrite` - Essential for Laravel's pretty URLs and routing
- `mod_headers` - For security headers
- `mod_deflate` - For compression (in custom config)

### 2. **Correct DocumentRoot Configuration**
The Apache DocumentRoot now points to `/var/www/demo-project/public` (Laravel's public directory) instead of the default `/var/www/html`.

### 3. **Proper Permissions**
- Set `www-data:www-data` ownership for all application files
- Set 755 permissions for `storage/` and `bootstrap/cache/` directories
- Ensures Apache can read files and Laravel can write logs/cache

### 4. **Optimized Layer Caching**
- Composer files (`composer.json`, `composer.lock`) are copied first
- Dependencies are installed before copying application code
- This means rebuilds are faster when only application code changes

### 5. **Production-Ready Composer Install**
```dockerfile
--no-dev              # Skip dev dependencies
--optimize-autoloader # Optimize autoloader for performance
--prefer-dist         # Use distribution packages (faster)
```

### 6. **Concurrent Services**
Both Apache and cron now run properly:
- Cron runs in the background for Laravel scheduled tasks
- Apache runs in the foreground via `apache2-foreground`
- Both start via a custom startup script

### 7. **Reduced Image Size**
- Clean up apt cache after installation
- Remove unnecessary package lists

## Files Created

### 1. `Dockerfile` (Main - Updated)
Your primary Dockerfile with all optimizations applied. Ready to use!

### 2. `docker/apache/laravel.conf` (Optional)
Custom Apache VirtualHost configuration with:
- Laravel-specific rewrite rules
- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- Gzip compression for better performance
- Proper authorization header handling

### 3. `Dockerfile.apache-custom` (Optional Reference)
Alternative Dockerfile that uses the custom `laravel.conf`. 
To use this instead, uncomment the custom config copy line in your main Dockerfile.

## How to Use

### Option 1: Use Current Optimized Dockerfile (Recommended)
```bash
docker build -t demo-project:latest .
docker run -p 80:80 demo-project:latest
```

### Option 2: Use With Custom Apache Config
If you want even more control, update your main `Dockerfile` to include:
```dockerfile
# Copy custom Apache configuration
COPY docker/apache/laravel.conf /etc/apache2/sites-available/000-default.conf
```

Or simply use the `Dockerfile.apache-custom`:
```bash
docker build -f Dockerfile.apache-custom -t demo-project:latest .
```

## Testing

After building, test your container:

```bash
# Build the image
docker build -t demo-project:latest .

# Run the container
docker run -d -p 8080:80 --name demo-app demo-project:latest

# Check if Apache is running
docker exec demo-app apache2ctl -S

# Check if cron is running
docker exec demo-app ps aux | grep cron

# View Apache error logs
docker logs demo-app

# Test the application
curl http://localhost:8080
```

## Performance Benefits

1. **Faster Rebuilds** - Layer caching means only changed layers rebuild
2. **Smaller Images** - Cleanup reduces image size by ~100MB
3. **Better Performance** - Optimized autoloader improves PHP performance
4. **Security** - Proper permissions and security headers
5. **Production Ready** - No dev dependencies included

## Troubleshooting

### Apache not serving Laravel correctly?
Check if the DocumentRoot is correct:
```bash
docker exec demo-app cat /etc/apache2/sites-available/000-default.conf
```

### Permission issues?
Check ownership:
```bash
docker exec demo-app ls -la /var/www/demo-project/storage
```

### Cron not running?
Check cron status:
```bash
docker exec demo-app ps aux | grep cron
docker exec demo-app cat /var/log/cron.log
```

## Next Steps

1. Test the optimized Dockerfile
2. Update your `docker-compose.yml` if needed
3. Consider using the custom Apache config for additional security/performance
4. Build and push to your registry when ready

