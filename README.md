Sensu configuration
===================

Set up a check in Sensu for the given cluster, e.g.: `CHECK_discovery_split_brain`,
which should be calling `check-brain.sh`.


Running in Docker
=================

`docker build -t soda/sensu-split-brain-check .`


```
docker run \
-e RABBITMQ_HOST=172.17.0.3 \
-e RABBITMQ_USER=test_user \
-e RABBITMQ_PASS=secret_password \
-e SENSU_CLIENT_NAME=discovery_split_brain_check \
-e SENSU_SUBSCRIPTION=CHECK_discovery_split_brain \
-e AWS_ACCESS_KEY_ID=AKIAI... \
-e AWS_SECRET_ACCESS_KEY=wJalrXUtnFE... \
-e AWS_DEFAULT_REGION=eu-west-1 \
-e CLUSTER=discovery \
-e SERVICES="discovery-api-service,discovery-plugins-service,profile-v3-plugin-service" \
soda/sensu-split-brain-check
```

Running on ECS
==============

The following explains how we could assume roles and get temporary credentials:
    - http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
    - http://dustinrcollins.com/grabbing-aws-credentials-with-bash

But it turns out that when running in ECS it already has that role and it doesn't seem to need
any temporary credentials or AWS keys to query the ECS metadata.


Configuring the system to be monitored
======================================

The following settings need to be present in the `JAVA_OPTS` to enable connection to remote JXM:

    ```
    -Dcom.sun.management.jmxremote.port=<a-port> \
    -Dcom.sun.management.jmxremote.rmi.port=<another-port> \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Djava.rmi.server.hostname=<EC2-host-IP>
    ```

When connected to, the process will respond with its hostname and a random port,
which is why the `.rmi.port` has to be set to something the firewall allows,
and the `.rmi.server.hostname` to something that the other side can resolve, i.e.
not the internal IP of the container.

This can be set up before launching the application like this:

    ```
    export HOST_IP=`curl --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4`
    export JAVA_OPTS="$JAVA_OPTS -Djava.rmi.server.hostname=$HOST_IP"
    ```

Make sure all ports are unique to the given service and the port ranges are allowed in the
Security Groups where the services and the monitoring component are deployed.