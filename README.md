# n8n Docker Setup

A Docker Compose setup to self-host n8n, featuring PostgreSQL database, Redis queue management, and scalable architecture.

## 🚀 Features

- **Complete Stack**: n8n with PostgreSQL database and Redis queue
- **Operational basics**: Resource limits, health checks, and backup scripts
- **Cloud notes**: Deployment guides for Render.com and other platforms
- **Secure Configuration**: Environment-based secrets management
- **Scalable**: Multi-worker architecture with queue processing
- **Development Friendly**: Local development with Docker Compose

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- Git (for cloning and version control)
- 4GB+ RAM available for containers

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
git clone <your-repository-url>
cd n8n-docker
```

### 2. Configure Environment

Copy and customize the environment file:

```bash
cp .env.example .env
```

**⚠️ SECURITY SETUP REQUIRED**: You must configure secure credentials:

```bash
# REPLACE THESE WITH YOUR OWN SECURE PASSWORDS!
POSTGRES_PASSWORD=your-secure-24char-password
POSTGRES_NON_ROOT_PASSWORD=your-secure-24char-password  
ENCRYPTION_KEY=your-secure-32char-encryption-key

# Webhook URL (update for production)
WEBHOOK_URL=http://localhost:5678
```

**🔐 Generate Secure Credentials**:
```bash
# Generate strong PostgreSQL passwords (24+ characters)
openssl rand -base64 32 | tr -d "=+/" | cut -c1-24

# Generate secure encryption key (32+ characters)  
openssl rand -base64 48 | tr -d "=+/" | cut -c1-32
```

**🔒 Security checklist**:
- Set strong random passwords (24+ characters) for database access
- Set a secure encryption key (32+ characters) for n8n data protection
- Run `chmod 600 .env` so only the owner can read and write it
- Environment variables protected from version control via `.gitignore`

### 3. Start the Stack

```bash
docker-compose up -d
```

### 4. Access n8n

Open your browser and navigate to: http://localhost:5678

## 📁 Project Structure

```
n8n-docker/
├── README.md                 # This file
├── docker-compose.yml        # Main Docker configuration
├── Dockerfile               # n8n container definition
├── .env.example             # Environment variables template
├── scripts/                 # Backup and restore scripts
├── .gitignore              # Git ignore rules
├── init-data.sh            # PostgreSQL initialization
└── docs/                   # Documentation directory
    ├── deployment-options.md  # Free hosting alternatives guide
    └── tasks.md              # Improvement roadmap
```

## 🐳 Docker Services

| Service | Description | Port | Resources |
|---------|-------------|------|-----------|
| **n8n** | Main workflow engine | 5678 | 1 CPU, 512MB RAM |
| **n8n-worker** | Background job processor | - | 1 CPU, 512MB RAM |
| **postgres** | Database | internal | 1 CPU, 1GB RAM |
| **redis** | Queue & cache | internal | 0.5 CPU, 256MB RAM |

## 🔧 Configuration

### Environment Variables

| Variable | Description | Security Status |
|----------|-------------|----------------|
| `POSTGRES_PASSWORD` | PostgreSQL admin password | 🔐 Must set secure 24+ char password |
| `POSTGRES_NON_ROOT_PASSWORD` | n8n database user password | 🔐 Must set secure 24+ char password |
| `ENCRYPTION_KEY` | n8n data encryption key | 🔐 Must set secure 32+ char key |
| `WEBHOOK_URL` | Public webhook URL | `http://localhost:5678` |

### Health Checks

All services include health checks:
- **PostgreSQL**: Connection test every 5s
- **Redis**: Ping test every 5s
- **n8n**: Automatic restart on failure

### Resource Management

Resource limits are configured for all containers:
- CPU limits prevent resource exhaustion
- Memory limits ensure stable operation
- Restart policies handle failures gracefully

### Data Persistence & Backup

**Redis Persistence**: Configured with AOF (Append Only File) and RDB snapshots:
- AOF sync every second for durability
- RDB snapshots at 900s/1 change, 300s/10 changes, 60s/10000 changes
- Data persisted to `redis_storage` Docker volume

**PostgreSQL Persistence**: All data stored in `./postgres_data`. Backups run manually or through the cron script in `scripts/`

## 💾 Backup & Restore

### Automated Backup Scripts

The setup includes comprehensive backup scripts in the `scripts/` directory:

#### PostgreSQL Backup
```bash
# Manual backup
./scripts/backup-postgres.sh

# Automated daily backups (2 AM)
./scripts/setup-backup-cron.sh
```

**Features**:
- Creates compressed SQL dumps with timestamps
- Automatically cleans up old backups (keeps 7 most recent)
- Configurable backup retention and directories
- Logs backup size and completion status
- **Execution Logging**: All backup operations logged to timestamped log files

#### Redis Backup
```bash
# Manual backup
./scripts/backup-redis.sh
```

**Features**:
- Backs up both RDB and AOF files
- Triggers BGSAVE for consistent snapshots
- Compressed storage with automatic cleanup
- Preserves Redis persistence data
- **Execution Logging**: All backup operations logged to timestamped log files

#### Complete Backup
```bash
# Backup both PostgreSQL and Redis
./scripts/backup-all.sh
```

**Features**:
- Coordinates both PostgreSQL and Redis backups
- **Execution Logging**: All master backup operations logged to timestamped log files

### Backup Logging

All backup scripts now include comprehensive execution logging:

**Log Files Created**:
- `backup-postgres_YYYYMMDD_HHMMSS.log` - PostgreSQL backup execution log
- `backup-redis_YYYYMMDD_HHMMSS.log` - Redis backup execution log  
- `backup-all_YYYYMMDD_HHMMSS.log` - Master backup script execution log
- `setup-backup-cron_YYYYMMDD_HHMMSS.log` - Cron setup execution log

**Log Content**:
- Timestamped entries with `[YYYY-MM-DD HH:MM:SS]` format
- All backup status messages and progress updates
- Success/failure notifications and error details
- Backup file sizes and cleanup operations
- Complete execution trail for troubleshooting

**Benefits**:
- **Verification**: Confirm backup execution and success status
- **Troubleshooting**: Detailed error logs for failed backups
- **Monitoring**: Track backup performance and file sizes
- **Audit Trail**: Complete history of backup operations

### Restore Procedures

#### PostgreSQL Restore
```bash
# List available backups
./scripts/restore-postgres.sh

# Restore latest backup
./scripts/restore-postgres.sh latest

# Restore specific backup
./scripts/restore-postgres.sh backups/n8n_backup_20250810_140000.sql.gz
```

**Restore Process**:
1. Automatically stops n8n services to prevent conflicts
2. Restores database from compressed or uncompressed backups  
3. Restarts n8n services after successful restore
4. Provides confirmation prompts for safety

#### Backup Storage

```
backups/              # Backup directory
├── n8n_backup_20250810_140000.sql.gz      # PostgreSQL dumps
├── n8n_backup_20250810_120000.sql.gz      # PostgreSQL dumps  
├── redis_backup_20250810_140000.rdb.gz    # Redis RDB snapshots
├── redis_backup_20250810_140000.aof.gz    # Redis AOF files
├── backup-postgres_20250810_140000.log    # PostgreSQL backup logs
├── backup-redis_20250810_140000.log       # Redis backup logs
├── backup-all_20250810_140000.log         # Master backup logs
└── setup-backup-cron_20250810_140000.log  # Cron setup logs
```

## ☁️ Cloud Deployment

For detailed deployment instructions on free hosting platforms, see:

📚 **[Complete Deployment Guide](docs/render-deployment.md)** - Step-by-step instructions for deploying on Render.com (completely free)

Additional free platforms covered in [docs/deployment-options.md](docs/deployment-options.md)

## 🔒 Security Considerations

### Immediate Actions Required

1. **Change Default Passwords**: Update all passwords in `.env`
2. **Generate Encryption Key**: Create a secure 32+ character key
3. **File Permissions**: Set `.env` to read-only (`chmod 600 .env`)
4. **Network Security**: Configure custom Docker networks for production

### Security Features

- Environment variables protected by `.gitignore`
- Database connections isolated within Docker network
- Resource limits reduce the impact of a runaway container
- Health checks report service status

## 🚨 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

#### Database Connection Errors
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify environment variables
docker-compose config

# Test database connectivity
docker-compose exec postgres pg_isready -h localhost -U n8n -d n8n
```

#### Memory Issues
```bash
# Check resource usage
docker stats

# Increase Docker memory allocation (Docker Desktop)
# Or adjust resource limits in docker-compose.yml
```

### Performance Optimization

- **CPU**: Increase CPU limits for heavy workflows
- **Memory**: Monitor usage and adjust limits accordingly  
- **Database**: Consider connection pooling for high-volume setups
- **Workers**: Scale n8n-worker replicas for parallel processing

## 📚 Additional Resources

- **[n8n Documentation](https://docs.n8n.io/)** - Official n8n guides
- **[Docker Compose Reference](https://docs.docker.com/compose/)** - Docker configuration help
- **[Render Documentation](https://render.com/docs)** - Free hosting platform docs
- **[PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)** - Database optimization
- **[Tasks & Improvements](docs/tasks.md)** - Prioritized enhancement roadmap

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Improvement Roadmap

See [docs/tasks.md](docs/tasks.md) for a prioritized list of 65+ improvement tasks covering:

- 🔴 **Critical**: Security vulnerabilities and data protection
- 🟠 **High**: Infrastructure stability and security hardening  
- 🟡 **Medium**: Production readiness and monitoring
- 🔵 **Low**: Performance optimizations and advanced features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚡ Quick Commands

```bash
# Start all services
docker-compose up -d

# Stop all services  
docker-compose down

# View logs
docker-compose logs -f

# Update and restart
docker-compose pull && docker-compose up -d

# Backup database
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql

# Access n8n CLI
docker-compose exec n8n n8n --help
```

---

**🎉 Happy Automating!** Your n8n instance is ready for workflow creation. Access it at http://localhost:5678 and start building powerful automation workflows.
