#!/bin/bash
set -eux

cp /usr/local/alluxio/core/client/runtime/target/alluxio-core-client-runtime-*-jar-with-dependencies.jar /usr/hdp/2.*/hadoop/
cp /usr/local/alluxio/conf/alluxio-site.properties /etc/hadoop/conf/



