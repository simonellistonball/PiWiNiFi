PiWiNiFi
========

A demo collecting wifi admin packets with a raspberry pi, and pushing them to nifi.

Self-contained docker edition
-----------------------------

There are several services

cloud: bastion box version, router
  * nifi
  * provisioner

secloud: analytics cluster
  * solr,
  * kafka
  * hdfs, hbase
  * zookeeper
  * nifi

booth:
  * nifi - command distribution
  * web - visualisation tool

pi:
  * nifi
  * wifi monitoring scripts

docker-nifi is a docker image build for the nifi used, use the build.sh script there to make a nifi docker image for all the others.

Each service includes a run command, which assumes a docker environment. Note that for the cloud environment this needs to be linked to a publicly accessible port. The other key thing to note is that you MUST specify -p port:port to have the same ports, or remotes will not work.

Each system is setup to allow site-to-site.

All nifis are SSL secured. The CA can be created locally, however, key parts will be uploaded to the provisioner application so it can create certificates for the pis.


Custom nars used:
https://github.com/jfrazee/nifi-put-site-to-site-bundle
https://github.com/simonellistonball/nifi-Twilio
