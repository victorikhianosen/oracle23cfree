# create oinstall group and create user oracle with group access
sudo groupadd -g 54321 oinstall
sudo useradd -u 54321 -g 54321 oracle