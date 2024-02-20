export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
rman target / cmdfile=/host/scripts/backup.rman
