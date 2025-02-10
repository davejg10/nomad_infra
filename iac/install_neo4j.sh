# Setting frontend to noninteractive to avoid password prompts
export DEBIAN_FRONTEND=noninteractive

NEO4J_DATA_DIR="/datadisk"

# Install java
sudo apt install openjdk-21-jre-headless -y

# Add neo4j repository to package manager
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg
echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable latest' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt-get update

# In ubuntu need to make sure the universe repository enabled
sudo add-apt-repository universe -y

# Programatiicaly find datadisk name by suggesting size and mountpoint empty
DATADISK=$(lsblk -d -n -o NAME,SIZE,MOUNTPOINT | awk -v size="${neo4j_data_disk_size_gb}G" '$2 == size  && $3 == "" {print $1}' | head -1)

# Mount disk
sudo mkdir $NEO4J_DATA_DIR
sudo mount /dev/$DATADISK $NEO4J_DATA_DIR
# Add to fstab for persistence
echo "/dev/$DATADISK $NEO4J_DATA_DIR ext4 defaults 0 0" | sudo tee -a /etc/fstab

# Install Neo4j
sudo apt-get install neo4j=${neo4j_version} -y

# Stop Neo4j
sudo systemctl stop neo4j

# Update Neo4j config to point to data disk
sudo sed -i "s|server.directories.data=.*|server.directories.data=$NEO4J_DATA_DIR/neo4j/data|" /etc/neo4j/neo4j.conf
sudo sed -i "s|server.directories.import=.*|server.directories.import=$NEO4J_DATA_DIR/neo4j/import|" /etc/neo4j/neo4j.conf
sudo sed -i "s|server.directories.plugins=.*|server.directories.plugins=$NEO4J_DATA_DIR/neo4j/plugins|" /etc/neo4j/neo4j.conf
sudo sed -i "s|server.directories.logs=.*|server.directories.logs=$NEO4J_DATA_DIR/neo4j/log|" /etc/neo4j/neo4j.conf

# Make neo4j reachable from clients other than localhost 
sudo sed -i "s|#server.default_listen_address=.*|server.default_listen_address=0.0.0.0|" /etc/neo4j/neo4j.conf
sudo sed -i "s|#server.http.listen_address=.*|server.http.listen_address=:7474|" /etc/neo4j/neo4j.conf
sudo sed -i "s|#server.bolt.listen_address=.*|server.bolt.listen_address=:7687|" /etc/neo4j/neo4j.conf

sudo chown -R neo4j:neo4j $NEO4J_DATA_DIR/neo4j

# Create directories
if [[ "${neo4j_snapshot_found}" == "false" ]]; then
    sudo mkdir -p $NEO4J_DATA_DIR/neo4j/{data,import,plugins,log}
    # Set the initial password (only works before the database has been started).
    sudo neo4j-admin dbms set-initial-password ${neo4j_pass}
else
    # Disable authentication because the password passed into this script may not be the same as the previous password.
    sudo sed -i "s|#dbms.security.auth_enabled=.*|dbms.security.auth_enabled=false|" /etc/neo4j/neo4j.conf
    sudo systemctl restart neo4j 
    until nc -z localhost 7687; do   
        sleep 5
    done
    echo "ALTER USER neo4j SET PASSWORD \"${neo4j_pass}\";" | cypher-shell -u neo4j -d system
    sudo sed -i "s|dbms.security.auth_enabled=.*|#dbms.security.auth_enabled=false|" /etc/neo4j/neo4j.conf
fi

# Start neo4j automatically on system startup
sudo systemctl enable neo4j

# Start the database
sudo systemctl restart neo4j

# Create read only user for nomad-backend - can only do this with enterprise license
# cypher-shell -u neo4j -p password "CREATE USER readonlyuser SET PASSWORD 'yourpassword' CHANGE NOT REQUIRED"
# cypher-shell -u neo4j -p password "GRANT MATCH, READ {*} ON DATABASE mydatabase TO readonlyuser"

exit 0 

