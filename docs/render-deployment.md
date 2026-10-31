# Deploy n8n on Render.com - Complete Guide

This guide provides comprehensive instructions for deploying your n8n Docker setup on Render.com's free tier.

## 🆓 Why Render.com?

Render.com offers the best truly free hosting solution for n8n:

- **750 hours/month free tier** (completely free, no credit system)
- **Automatic HTTPS** with custom domains included
- **Docker support** with seamless GitHub integration
- **No service sleeping** during active usage
- **Professional webhook URLs** for production workflows
- **Free PostgreSQL database** (90 days, easily renewable)

## 📋 Prerequisites

Before starting, ensure you have:
- A GitHub account with this repository forked
- A Render.com account (free signup)
- Your environment variables configured (see main README.md)

## 🚀 Quick Deployment Steps

### Step 1: Prepare Your Repository

1. **Fork this repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/n8n-docker-setup.git
   cd n8n-docker-setup
   ```

3. **Update environment variables** for production:
   ```bash
   # Update WEBHOOK_URL in .env
   WEBHOOK_URL=https://your-app-name.onrender.com
   ```

### Step 2: Create Render Services

#### 2.1 PostgreSQL Database

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New"** → **"PostgreSQL"**
3. Configure the database:
   - **Name**: `n8n-postgres`
   - **Database**: `n8n`
   - **User**: `n8n`
   - **Region**: Choose closest to your location
   - **Plan**: Select **"Free"** (90 days, renewable)

4. **Save database credentials**:
   ```
   Database: n8n
   Username: n8n
   Password: [generated password]
   Hostname: [generated hostname]
   Port: 5432
   ```

#### 2.2 Redis Service

1. Click **"New"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure Redis service:
   - **Name**: `n8n-redis`
   - **Environment**: `Docker`
   - **Build Command**: Leave empty
   - **Start Command**: `redis-server --appendonly yes`
   - **Plan**: **"Free"**

#### 2.3 Main n8n Application

1. Click **"New"** → **"Web Service"**
2. Select your forked repository
3. Configure the service:
   - **Name**: `n8n-app`
   - **Environment**: `Docker`
   - **Build Command**: Leave empty
   - **Start Command**: Leave empty (uses Dockerfile)
   - **Plan**: **"Free"**

### Step 3: Environment Variables

Configure these environment variables in your n8n service:

```bash
# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=[your-postgres-hostname]
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=[your-postgres-password]

# Redis Configuration  
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=[your-redis-hostname]
QUEUE_HEALTH_CHECK_ACTIVE=true

# Security
N8N_ENCRYPTION_KEY=[your-32-char-encryption-key]
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Webhook Configuration
WEBHOOK_URL=https://your-app-name.onrender.com

# Additional n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
```

### Step 4: Custom Domain (Optional)

1. In your n8n service settings, go to **"Settings"** → **"Custom Domain"**
2. Add your domain and follow DNS configuration instructions
3. Update `WEBHOOK_URL` environment variable with your custom domain

## 🔧 Configuration Files

### Dockerfile Optimization for Render

Ensure your `Dockerfile` is optimized for Render deployment:

```dockerfile
FROM docker.n8n.io/n8nio/n8n:latest

# Set environment variables
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Use the default n8n start command
CMD ["n8n", "start"]
```

### Environment Variables Management

Create a `.env.production` file for production-specific variables:

```bash
# Production Environment Configuration
NODE_ENV=production
N8N_METRICS=true
N8N_LOG_LEVEL=info
N8N_DISABLE_UI=false

# Performance Settings
N8N_PAYLOAD_DEFAULT_MAX_BUFFER=16MB
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=336
```

## 🔒 Security Best Practices

### 1. Secure Database Connection

```bash
# Enable SSL for PostgreSQL connection
DB_POSTGRESDB_SSL_CA=""
DB_POSTGRESDB_SSL_CERT=""
DB_POSTGRESDB_SSL_KEY=""
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false
```

### 2. Authentication Configuration

```bash
# JWT Configuration
N8N_JWT_AUTH_HEADER="Authorization"
N8N_JWT_AUTH_HEADER_VALUE_PREFIX="Bearer "

# User Management
N8N_USER_MANAGEMENT_DISABLED=false
N8N_PUBLIC_API_DISABLED=false
```

### 3. HTTPS Configuration

```bash
N8N_PROTOCOL=https
N8N_SSL_KEY=""
N8N_SSL_CERT=""
```

## 🚨 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs in Render dashboard
# Ensure Dockerfile is in repository root
# Verify all dependencies are properly defined
```

#### Database Connection Issues
```bash
# Verify database credentials in environment variables
# Check if database service is running
# Ensure network connectivity between services
```

#### Memory Issues
```bash
# Monitor service metrics in Render dashboard
# Consider upgrading to paid plan if needed
# Optimize workflows to reduce memory usage
```

#### Service Sleeping
```bash
# Free services sleep after 15 minutes of inactivity
# Use external monitoring to keep services warm
# Consider upgrading to paid plan for always-on services
```

### Performance Optimization

#### Resource Limits
- **Free Plan**: 0.5 CPU, 512MB RAM
- Monitor usage in Render dashboard
- Optimize workflows for resource constraints

#### Database Performance
```bash
# Enable connection pooling
DB_POSTGRESDB_POOL_SIZE=5

# Optimize query performance
N8N_DB_LOGGING_ENABLED=false
N8N_DB_LOGGING_OPTIONS_MAX_QUERY_EXECUTION_TIME=10000
```

## 📊 Monitoring & Maintenance

### Health Checks

Render automatically monitors your services, but you can add custom health checks:

```javascript
// Add to your n8n workflows
GET https://your-app-name.onrender.com/healthz
```

### Database Maintenance

```bash
# PostgreSQL maintenance (run monthly)
# Access via Render shell or external tool
VACUUM ANALYZE;
REINDEX DATABASE n8n;
```

### Backup Strategy

Since Render's free database expires after 90 days:

1. **Set up automated backups** using GitHub Actions
2. **Export workflows regularly** through n8n UI
3. **Store credentials securely** in environment variables

## 🔄 Scaling & Upgrades

### Horizontal Scaling

For higher traffic, consider:
- Upgrading to Render's paid plans
- Implementing load balancing
- Using Redis for session storage

### Vertical Scaling

Monitor resource usage and upgrade when needed:
- **Starter Plan**: $7/month, 1 CPU, 1GB RAM
- **Standard Plan**: $25/month, 2 CPU, 4GB RAM

## 📚 Additional Resources

- **[Render Documentation](https://render.com/docs)** - Official Render guides
- **[n8n Cloud Deployment](https://docs.n8n.io/hosting/)** - n8n deployment best practices  
- **[Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)** - Container optimization
- **[PostgreSQL on Render](https://render.com/docs/databases)** - Database management

## 🤝 Support

For issues specific to this deployment:
1. Check [Render Status Page](https://status.render.com/)
2. Review Render service logs in dashboard
3. Consult [Render Community](https://community.render.com/)
4. Open an issue in this repository

---

*Last updated: 2025-08-10*
