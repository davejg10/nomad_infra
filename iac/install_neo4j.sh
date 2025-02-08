# Setting frontend to noninteractive to avoid password prompts
export DEBIAN_FRONTEND=noninteractive

# Install java
sudo apt install openjdk-21-jre-headless -y

# Add neo4j repository to package manager
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg
echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable latest' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt-get update

# In ubuntu need to make sure the universe repository enabled
sudo add-apt-repository universe -y

# Install neo4j 
sudo apt-get install neo4j=${neo4j_version} -y

# Start neo4j automatically on system startup
sudo systemctl enable neo4j

# Set password
sudo neo4j-admin dbms set-initial-password mypassword

# Make neo4j reachable from clients other than localhost 
echo "server.default_listen_address=0.0.0.0" >> sudo tee -a /etc/neo4j/neo4j.conf
server.http.listen_address=:7474 >> sudo tee -a /etc/neo4j/neo4j.conf
server.bolt.listen_address=:7687 >> sudo tee -a /etc/neo4j/neo4j.conf

# Start the database
sudo systemctl start neo4j

exit 0 

