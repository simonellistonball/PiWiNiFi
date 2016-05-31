Build this as a Docker image. It contains nginx, uwsgi and the provisioning app.

Before building put jdk-8u91-linux-x64.tar.gz in the root. (Oracle JDK, sorry, can't do it for you).


data/: stores for the generated pi certs,
certs/: core certs.

Certificates go in certs/
server.crt from CA generation process
server.key from CA generation process, then decrypted (openssl rsa -in server.key.enc -out server.key)
ca.crt from CA generation process
dh.pem: openssl dhparam -out dh.pem 2048

This is all handled by installCerts.sh from ca/
