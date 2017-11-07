# hdinsight-scriptaction-alluxio

Script action to install and uninstall Alluxio to Azure HDInsight cluster.

Tested on HDInsight 3.5, with Azure CLI v0.10.16. The script should also work with other entries like Azure portal, powershell, etc.

## Install

You need have an HDInsight cluster at running (with Azure blob store as Hadoop default file system); Please find the resource group, cluster name from Azure portal. 

This script accepts two parameter: Alluxio version, and memory size allocated to Alluxio in each worker. And it will automatically mount the Azure blob store as Alluxio's underlying file system. 

Here is a sample using 1.6.1 and 2GB as inputs (replace with your resource group and cluster name):

```
azure login

azure hdinsight script-action create -g <resource-group> -n alluxio -c <hdinsight_cluster_name> -u https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio.sh -t "headnode;workernode" -p "1.6.1 2GB"
```

To persist the script in Azure, add the "--persistOnSuccess" flag.

Ideally it will print the result as below:

```
+ Executing Script Action on HDInsight cluster
data:    Operation Info
data:    ---------------
data:    Operation state:  Succeeded
data:    Operation ID:  661edce1-1f8a-44bb-af44-aa9bb7f88c7b
info:    hdinsight script-action create command OK
```

Then you can open a ssh tunnel to the cluster's primary headnode, then visit http://localhost:19999/ on your browser. You will see the Azure blob store files mounted in Alluxio.

![Alluxio on Azure blob store](https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio-azure-1.png)

You can browse and check a sample file:

![Alluxio on Azure blob store](https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio-azure-2.png)

If error, you can check the detail information in Azure portal.


## Configure on Ambari

Don't remember to register "alluxio" in core-site.xml; You can do this in HDInsight's Ambari, in "HDFS" -> "Configs" -> "Advanced" -> "Custom core-sites" -> "Add Property". 

```
<configuration>
  <property>
    <name>fs.alluxio.impl</name>
    <value>alluxio.hadoop.FileSystem</value>
  </property>
</configuration>
```

Save and then restart Hadoop services to take effective. When completed, you should be able to access alluxio via Hadoop API or CLI:

```
$ hadoop fs -ls alluxio://hn0-xxxxxxx:19998

Found 18 items
drwxrwxrwx   -                            0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/HdiApplications
drwxr-xr-x   - root   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/HdiSamples
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/ams
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/amshbase
drwxrwxrwx   - yarn   hadoop              0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/app-logs
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/apps
drwxr-xr-x   - yarn   hadoop              0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/atshistory
drwxr-xr-x   - root   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/custom-scriptaction-logs
drwxr-xr-x   - root   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/example
drwxr-xr-x   - hbase  supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/hbase
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/hdp
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/hive
drwxr-xr-x   - kylin  supergroup          9 2017-11-07 06:57 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/kylin
drwxr-xr-x   - mapred supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/mapred
drwx------   - kylin  supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/mapreducestaging
drwxrwxrwx   - mapred hadoop              0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/mr-history
drwxrwxrwx   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/tmp
drwxr-xr-x   - hdfs   supergroup          0 2017-11-07 05:35 alluxio://hn0-kapdem.tdrx1ytlzplujmndomfrdqv2ca.bx.internal.chinacloudapp.cn:19998/user

```

## Uninstall

If want to uninstall Alluxio, just run the uninstall script:

```
azure hdinsight script-action create -g <resource-group> -n alluxio-uninstall -c <hdinsight_cluster_name> -u https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio-uninstall.sh -t "headnode;workernode"
```