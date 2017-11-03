# hdinsight-scriptaction-alluxio

Script action to install and uninstall Alluxio to Azure HDInsight cluster.

Tested on HDInsight 3.5, with Azure CLI v0.10.16. The script should also work with other entries like Azure portal, powershell, etc.

## Install

You need have an HDInsight cluster at running (with Azure blob store as Hadoop default file system); Please find the resource group, cluster name from Azure portal. 

This script accepts two parameter: Alluxio version, and memory size allocated to Alluxio in each worker. And it will automatically mount the Azure blob store as Alluxio's underlying file system. 

Here is a sample using 1.6.0 and 2GB as inputs (replace with your resource group and cluster name):

```
azure login

azure hdinsight script-action create -g <resource-group> -n alluxio -c <hdinsight_cluster_name> -u https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio.sh -t "headnode;workernode" --persistOnSuccess -p "1.6.0 2GB"
```

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

If error, you can check the detail information in Azure portal.


## Uninstall

If want to uninstall Alluxio, just run the uninstall script:

```
azure hdinsight script-action create -g <resource-group> -n alluxio-uninstall -c <hdinsight_cluster_name> -u https://raw.githubusercontent.com/shaofengshi/hdinsight-scriptaction-alluxio/master/alluxio-uninstall.sh -t "headnode;workernode"
```