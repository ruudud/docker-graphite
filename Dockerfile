FROM lopter/raring-base:latest
MAINTAINER Louis Opter <louis@dotcloud.com>

RUN apt-get update && apt-get install -y python-cairo software-properties-common collectd libgcrypt11 git python-virtualenv supervisor sudo build-essential python-dev openssh-server openssh-client python-pip && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
RUN mkdir /var/run/sshd

# Install nodejs
RUN add-apt-repository -y ppa:chris-lea/node.js && apt-get update && apt-get install -y nodejs

# Separate user per daemon
RUN adduser --system --group --no-create-home collectd && adduser --system --home /opt/graphite graphite && adduser --system --home /opt/statsd statsd

# Install statsd
WORKDIR /opt/statsd
RUN sudo -u statsd git clone https://github.com/etsy/statsd.git . && git checkout v0.7.1

RUN pip install 'Twisted<12.0'

# Use --system-site-packages so it get access to pycairo (which cannot be installed via pip)
RUN sudo -u graphite virtualenv --system-site-packages ~graphite/env
ADD graphite/requirements.txt /opt/graphite/
RUN sudo chown -R graphite /opt/graphite
RUN sudo -u graphite HOME=/opt/graphite /bin/sh -c ". ~/env/bin/activate && pip install -r /opt/graphite/requirements.txt"

ADD statsd/config.js /opt/statsd/config.js
ADD collectd/collectd.conf /etc/collectd/
ADD supervisor/ /etc/supervisor/conf.d/
ADD graphite/local_settings.py /opt/graphite/webapp/graphite/
ADD graphite/wsgi.py /opt/graphite/webapp/graphite/
ADD graphite/mkadmin.py /opt/graphite/webapp/graphite/
ADD graphite/carbon.conf /opt/graphite/conf/
ADD graphite/storage-schemas.conf /opt/graphite/conf/

RUN sed -i "s#^\(SECRET_KEY = \).*#\1\"`python -c 'import os; import base64; print(base64.b64encode(os.urandom(40)))'`\"#" ~graphite/webapp/graphite/app_settings.py
RUN sudo -u graphite HOME=/opt/graphite PYTHONPATH=/opt/graphite/lib/ /bin/sh -c "cd ~/webapp/graphite && ~/env/bin/python manage.py syncdb --noinput"
RUN sudo -u graphite HOME=/opt/graphite PYTHONPATH=/opt/graphite/lib/ /bin/sh -c "cd ~/webapp/graphite && ~/env/bin/python mkadmin.py"

RUN echo "root:geheim" | chpasswd

# sshd, gunicorn, collectd, carbon/plaintext, carbon/pickle, carbon/amqp, statsd
EXPOSE 22 8080 25826/udp 2003 2004 7002 8125
CMD exec supervisord -n
