#!/bin/bash
set -eux

version=$1
memory_size=$2


# azure_blob_store_url sample: wasb://AZURE_CONTAINER@AZURE_ACCOUNT.blob.core.windows.net/AZURE_DIRECTORY/

echo "import HDInsight utilities script"
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh

masterdns=`get_primary_headnode`
## Check if values retrieved are empty, if yes, exit with error ##
if [[ -z $masterdns ]]; then
  echo "Could not determine primary headnode."
  exit 139
fi

if [ -d /usr/local/alluxio ]; then
    echo "alluxio has been installed, do nothing, exit..."
    exit 0
fi

azure_blob_store_url=`awk '/fs.defaultFS/{getline; print}' /etc/hadoop/conf/core-site.xml | grep -oP '<value>\K.*(?=</value>)'`
HADOOP_AZURE_JAR="`ls /usr/hdp/2.*/hadoop/hadoop-azure-2.7*.jar`"
HADOOP_COMMON_JAR="`ls /usr/hdp/2.*/hadoop/hadoop-common.jar`" 
HADOOP_AUTH_JAR="`ls /usr/hdp/2.*/hadoop/hadoop-auth.jar`" 
azure_storage_version="6.1.0"

mkdir -p /usr/local
mkdir -p /mnt/alluxio-hdd1
mkdir -p /alluxio-hdd2

# Download alluxio
if [ ! -f /tmp/alluxio-${version}-hadoop-2.7-bin.tar.gz ]; then
  wget http://alluxio.org/downloads/files/${version}/alluxio-${version}-hadoop-2.7-bin.tar.gz -P /tmp
fi

cd /usr/local
tar -zxf /tmp/alluxio-${version}-hadoop-2.7-bin.tar.gz
mv alluxio-${version}-hadoop-2.7 alluxio
wget "http://central.maven.org/maven2/com/microsoft/azure/azure-storage/${azure_storage_version}/azure-storage-${azure_storage_version}.jar" -P /usr/local/alluxio
AZURE_STORAGE_JAR="/usr/local/alluxio/azure-storage-${azure_storage_version}.jar" 

chmod -R 777 alluxio

initialize_alluxio () {
  cd /usr/local/alluxio
  # config
  sed -i '/ALLUXIO_WORKER_MEMORY_SIZE/d' ./conf/alluxio-env.sh
  echo "ALLUXIO_WORKER_MEMORY_SIZE=${memory_size}" >> ./conf/alluxio-env.sh
   

  echo "export ALLUXIO_CLASSPATH=${AZURE_STORAGE_JAR}:${HADOOP_COMMON_JAR}:${HADOOP_AUTH_JAR}:${HADOOP_AZURE_JAR}" >> conf/alluxio-env.sh

  cp conf/alluxio-site.properties.template conf/alluxio-site.properties
  echo "alluxio.security.authorization.permission.enabled=false" >> ./conf/alluxio-site.properties
  echo "alluxio.user.block.size.bytes.default=128MB" >> ./conf/alluxio-site.properties
  echo "alluxio.underfs.address=${azure_blob_store_url}" >> ./conf/alluxio-site.properties
  echo "alluxio.underfs.hdfs.prefixes=hdfs://,glusterfs:///,maprfs:///,wasb://" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.levels=2" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level0.alias=MEM" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level0.dirs.quota=${memory_size}" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level0.watermark.high.ratio=0.8" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level0.watermark.low.ratio=0.6" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level1.alias=HDD" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level1.dirs.path=/mnt/alluxio-hdd1,/alluxio-hdd2" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level1.dirs.quota=100GB,200GB" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level1.watermark.high.ratio=0.9" >> ./conf/alluxio-site.properties
  echo "alluxio.worker.tieredstore.level1.watermark.low.ratio=0.7" >> ./conf/alluxio-site.properties
  echo "alluxio.user.file.writetype.default=THROUGH" >> ./conf/alluxio-site.properties
  echo "alluxio.user.file.metadata.load.type=Always" >> ./conf/alluxio-site.properties
 
  cp /etc/hadoop/conf/core-site.xml conf/
  echo "" > conf/masters
  echo "" > conf/workers

  cp -f core/client/runtime/target/alluxio-core-client-runtime-*-jar-with-dependencies.jar /usr/hdp/2.*/hadoop/lib
  cp -f conf/alluxio-site.properties /etc/hadoop/conf/
}


if [[ $(hostname -f) = "${masterdns}" ]]; then 
  echo "Primary head node, install Alluxio master"
  cd /usr/local/alluxio
  # bootstrap
  ./bin/alluxio bootstrapConf ${masterdns}

  # initialize
  initialize_alluxio
 
  # Format
  ./bin/alluxio format
  # Start master
  ./bin/alluxio-start.sh master

else
  cd /usr/local/alluxio
  # bootstrap
  ./bin/alluxio bootstrapConf ${masterdns}  

  # initialize
  initialize_alluxio

  # Format
  ./bin/alluxio format
  # Start worker
  ./bin/alluxio-start.sh worker SudoMount

fi

mkdir -p /etc/alluxio
ln -s /usr/local/alluxio/conf/alluxio-site.properties /etc/alluxio/alluxio-site.properties

