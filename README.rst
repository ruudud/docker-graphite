collectd/statsd/Graphite on Docker
==================================

This repository contains the sources to build a collectd_/statsd_/Graphite_ Docker_
image. collectd and statsd is configured to receive metrics from the network and to store
them to Graphite.

If you have Docker installed, you can try it out with::

   docker build -t collectd-graphite . # from the root of this repository
   docker run collectd-graphite

Then, using ``docker ps``, write down which port has been assigned to collectd
and which one has been assigned to the web interface.

Send some test data to statsd::

    echo "footest:1|c" | nc -u -w0 <docker-ip-addr> <the-port-in-docker-ps-likely-8125>

Install collectd using your favorite package manager, open ``collectd.conf`` and
add::

   <Plugin network>
   	Server "<your-docker-host>" "<the-port-in-docker-ps-likely-49153>"
   </Plugin>
   
Restart collectd and point your browser to *http://<your-docker-host->:<the-other-port-in-docker-ps>*,
and you should see the Graphite UI. By navigating in the tree on the left, you
can start to build your own graphs.

If you want to save configured graphs, you can login into graphite with the
username *graphite* and the password *admin* (you change that from the
graphite/mkadmin.py script).

You can also access the container via ssh using the username *root* and password *geheim*.

.. _collectd: https://www.collectd.org/
.. _statsd: https://github.com/etsy/statsd
.. _Graphite: http://graphite.readthedocs.org/en/latest/
.. _Docker: http://www.docker.io/

.. vim: set tw=80 spelllang=en spell:
