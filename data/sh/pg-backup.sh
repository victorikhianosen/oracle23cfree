# Modify to the name of your postgresql database. Run as postgres user
export PG_BACKUP_DIR="/backup"
export PG_CONTAINER="postgresql15-postgres15-1"
docker exec -it ${PG_CONTAINER} sh /scripts/backup.sh
