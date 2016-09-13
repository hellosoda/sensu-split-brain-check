
`docker build -t dyk/sensucheck .`


```
docker run -e "RABBITMQ_HOST=172.17.0.3" \
-e "RABBITMQ_USER=test_user" \
-e "RABBITMQ_PASS=secret_password" \
-e "SENSU_CLIENT_NAME=split_brain_check" \
-e "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE" \
-e "AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
-e "AWS_DEFAULT_REGION=us-west-2" \
dyk/sensucheck
```
