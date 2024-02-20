 # shell script to start oracle23cfree
 # configure crontab to execute on startup
 # @reboot  /usr/bin/sh /home/jonathan/Projects/lumen-swift-parser/oracle23cfree-start.sh
 /usr/bin/docker compose -f /home/jonathan/oracle23cfree/docker-compose.yml up -d