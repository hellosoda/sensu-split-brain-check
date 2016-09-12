
`docker build -t dyk/sensucheck .`


```
docker run -e "RABBITMQ_HOST=172.17.0.3" \
-e "RABBITMQ_USER=test_user" \
-e "RABBITMQ_PASS=secret_password" \
-e "SENSU_CLIENT_NAME=split_brain_check" \
-e "AKKA_CLUSTER_NODES=172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11"  dyk/sensucheck
```
