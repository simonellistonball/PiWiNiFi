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
* https://github.com/jfrazee/nifi-put-site-to-site-bundle
* https://github.com/simonellistonball/nifi-Twilio


How To build
------------

in ca/

    ./makeCA.sh && ./makeAllKeys.sh && ./installCerts.sh

you will have to import the new `ca/CA/cacert.pem` to your keychain, and your relevant `ca/users/<name>/<name>.p12` private key using the password in the same folder.

Build the nifi docker image in docker-nifi (./build.sh)

Build the provisioner image in cloud/provisioner (./build.sh)

run the provisioner docker (cd cloud/provisioner/ && ./runProvisioning.sh)
run each nifi docker (secloud|booth|cloud/nifi/ && ./runNifi.sh)

##TODO:
1. some of the keystore properties will need setting in the nifi flows. This should really be scripted through API calls.
2. Pi image builder needs incorporating to this repo
3. Some integration tests wouldn't hurt.
