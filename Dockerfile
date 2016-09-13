FROM java:8

# sensu see https://hub.docker.com/r/anroots/sensu/~/dockerfile/

# Install Sensu
RUN apt-get update && \
	apt-get install -y curl && \
	curl -O https://core.sensuapp.com/apt/pool/sensu/main/s/sensu/sensu_0.25.7-1_amd64.deb && \
	echo '1ae485c98e1186be7fa218921fa9c8afb6f1aff8 sensu_0.25.7-1_amd64.deb' >> sha1sums.txt && \
	sha1sum -c sha1sums.txt && \
	dpkg -i sensu_0.25.7-1_amd64.deb && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/* /etc/sensu/config.json.example sensu_0.25.7-1_amd64.deb sha1sums.txt

# Update PATH to include the embedded Ruby shipped with Sensu
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/sensu/embedded/bin:/etc/sensu/plugins

RUN apt-get update && apt-get install -y vim jq bsdtar awscli

RUN curl -L http://downloads.typesafe.com/akka/akka_2.11-2.4.7.zip | bsdtar -xvf - -C /opt/
RUN chmod +x /opt/akka-2.4.7/bin/akka-cluster


COPY check-brain.sh /etc/sensu/plugins/check-brain.sh
RUN chmod +x /etc/sensu/plugins/check-brain.sh

#dockerize
ENV DOCKERIZE_VERSION v0.2.0
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | \
    tar -C /usr/local/bin -xzvf - 

COPY conf.d /etc/sensu/conf.d/

CMD ["sh", "-c", "exec /usr/local/bin/dockerize \
 -wait tcp://${RABBITMQ_HOST}:5672 \
 -template /etc/sensu/conf.d/rabbitmq.tmpl:/etc/sensu/conf.d/rabbitmq.json \
 -template /etc/sensu/conf.d/client.tmpl:/etc/sensu/conf.d/client.json \
 /opt/sensu/bin/sensu-client -d /etc/sensu/conf.d"]

