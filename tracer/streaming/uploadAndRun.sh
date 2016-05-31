#!/bin/bash
#scp target/scala-2.10/streaming-assembly-1.0.jar hs16w01.cloud.hortonworks.com:~ && \

sbt compile && \
rsync --exclude target --exclude bin -zvre ssh ./ hs16w01.cloud.hortonworks.com:~/sparkStuff && \
ssh hs16w01.cloud.hortonworks.com 'cd sparkStuff ; sbt assembly && /usr/hdp/current/spark-client/bin/spark-submit \
  --num-executors 3 --executor-memory 4g --executor-cores 2 --master yarn-client \
  --conf "spark.driver.extraJavaOptions=-Dlog4j.configuration=log4j-spark.properties" \
  --conf "spark.executor.extraJavaOptions=-Dlog4j.configuration=log4j-spark.properties" \
  --class com.simonellistonball.hadoopsummit16.Streaming ~/sparkStuff/target/scala-2.10/streaming-assembly-1.0.jar \
  hs16w05.cloud.hortonworks.com:6667,hs16w06.cloud.hortonworks.com:6667,hs16w07.cloud.hortonworks.com:6667 devices \
  2>&1'
