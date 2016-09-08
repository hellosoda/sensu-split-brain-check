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
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/sensu/embedded/bin

#dockerize
ENV DOCKERIZE_VERSION v0.2.0
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | \
    tar -C /usr/local/bin -xzvf - 

# supervisord
RUN wget http://peak.telecommunity.com/dist/ez_setup.py;python ez_setup.py \
  && easy_install supervisor

COPY supervisord.conf /etc/supervisord.conf


COPY conf.d /etc/sensu/conf.d/

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]

