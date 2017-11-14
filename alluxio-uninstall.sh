#!/bin/bash
set -eux

echo "import HDInsight utilities script"
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh

masterdns=`get_primary_headnode`
## Check if values retrieved are empty, if yes, exit with error ##
if [[ -z $masterdns ]]; then
  echo "Could not determine primary headnode, exit"
  exit 139
fi

if [ ! -d /usr/local/alluxio ]; then
    echo "alluxio not installed, do nothing..."
    exit 0
fi 

if [[ $(hostname -f) = "${masterdns}" ]]; then 
  echo "Primary head node, running alluxio master"
  cd /usr/local/alluxio
  # stop master
  ./bin/alluxio-stop.sh master

else
  cd /usr/local/alluxio
  # stop worker
  ./bin/alluxio-stop.sh worker

fi

cd / && rm -rf /usr/local/alluxio
rm -rf /etc/alluxio
rm -rf /mnt/alluxio-hdd1
rm -rf /alluxio-hdd2

