# For deleting obsolete trace files
OBS_IN_MIN=4320 # 3 days
for f in $( adrci exec="show homes" | grep -v "ADR Homes:" );
do
  echo "Start Purging ${f} at $(date)";
  adrci exec="set home $f; purge -age $OBS_IN_MIN ;" ;
done

# For deleting obsolete audit files
#find /opt/oracle/admin/XE/adump -type f -mtime +3 -name '*.aud' -exec rm -f {} \;
