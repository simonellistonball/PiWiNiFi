#!/bin/bash

docker rmi  simonellistonball/nifi
docker build -t simonellistonball/nifi ./
