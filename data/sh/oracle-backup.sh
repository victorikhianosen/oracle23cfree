export ORACLE_CONTAINER="oracle23cfree-23cfree-1"
/usr/bin/docker exec -it ${ORACLE_CONTAINER} rman target / cmdfile=/data/scripts/backup.rman
