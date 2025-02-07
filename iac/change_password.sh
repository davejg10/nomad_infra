echo "Checking if Neo4j is up and changing password...."
while true; do
   if curl -s -I http://localhost:7474 | grep "200 OK"; then
     echo "Neo4j is up; changing default password" 2>&1
     curl -v -H "Content-Type: application/json" \
       -XPOST -d '{"password":"'$NEO4J_PASSWORD'"}' \
       -u neo4j:neo4j \
       http://localhost:7474/user/neo4j/password 2>&1
     echo "Password reset, signaling success" 2>&1
     break
   fi
   echo "Waiting for neo4j to come up" 2>&1
   sleep 1
done