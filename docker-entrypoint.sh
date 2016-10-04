#!/bin/bash

# Start the Sensu client as a child process with `exec` so it receives signals.
exec /usr/local/bin/dockerize \
    -wait tcp://${RABBITMQ_HOST}:5672 \
    -template /etc/sensu/conf.d/rabbitmq.tmpl:/etc/sensu/conf.d/rabbitmq.json \
    -template /etc/sensu/conf.d/client.tmpl:/etc/sensu/conf.d/client.json \
    /opt/sensu/bin/sensu-client -d /etc/sensu/conf.d