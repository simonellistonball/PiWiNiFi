Certificates go in certs/

server.crt from CA generation process
server.key from CA generation process, then decrypted (openssl rsa -in server.key.enc -out server.key)
ca.crt from CA generation process

dh.pem: openssl dhparam -out dh.pem 2048
