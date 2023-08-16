#!/bin/bash
echo "####################################################################"
echo "##### Welcome to load testing and captures"
echo "####################################################################"
Wait5mins=300
Wait10mins=500
Wait15mins=900
Wait20mins=1200

if command -v oc > /dev/null; then
    echo "Great! oc cli available."
else
    echo "ERROR: oc command does not exist."
    echo "Download from https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.12/openshift-client-linux.tar.gz"
    exit 1
fi   

if command -v kube-burner > /dev/null; then
    echo "Great! kube-burner cli available."
else
    echo "ERROR: kube-burner command does not exist."
    exit 1
fi   

if [[ -z "${KUBECONFIG}" ]]; then
    echo "ERROR: KUBECONFIG environment variable not defined."
    exit 1
else
    echo "Great! Found KUBECONFIG"
fi 

# try executing the command
CONSOLE_URL=$(oc whoami --show-console)

if [[ "$?" == 0 ]]; then 
    echo "Great! seems to be working"
else
    echo "ERROR: oc execution with errors"
    exit 1
fi

# make sure it has the admin-ack to avoid getting stuck in upgrade testing
oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.12-kube-1.26-api-removals-in-4.13":"true"}}' --type=merge

oc get clusterversion ; oc get nodes ; oc get co

# echo "Creating new TOKEN for Prometheus API"
oc apply -f data-collector/manifests/00-prometheus-api-token.yaml

# echo "Acquiring Prometheus Token"
export TOKEN=`oc -n openshift-monitoring extract secret/prometheus-api-token --to=- --keys=token`

# echo "Retrieving route for the Prometheus endpoint"
export PROMETHEUS_URL=$(oc get route -n openshift-monitoring prometheus-k8s -o jsonpath="{.status.ingress[0].host}")

# cd data-collector
TIMESTAMP=$(date +%+4Y%m%d-%H%M%S)
config_file=config-auto-$TIMESTAMP.yaml
envsubst < data-collector/config-template.yaml > data-collector/$config_file

wait_for_stable_cluster() {
    while true ; do
        echo "Checking if cluster operators are stable for 15s..."
        check_stable=$(oc adm wait-for-stable-cluster --minimum-stable-period=5s)

        TS=$(date +%+4Y%m%d-%H%M%S)
        if [[ "${check_stable}" =~ .*"All clusteroperators are stable".* ]] ; then
            echo "Great! Cluster operators are stable!"
            break 
        else 
            echo ${TS} "Waiting for cluster operators to be stable..."
            sleep 15
        fi
    done
}

echo "####################################################################"
echo "##### Initiating captures in the background"
echo "####################################################################"

run_capture="cd data-collector && source ./venv/bin/activate && python main.py --config $config_file ; deactivate"
nohup bash -c "$run_capture" > nohup-$TIMESTAMP &
CAPTURE_PID=$(jobs -p)
echo $CAPTURE_PID > run-$TIMESTAMP.pid

echo "####################################################################"
echo "##### Sleeping 15mins for captures..."
echo "####################################################################"
sleep $Wait15mins

echo "####################################################################"
echo "##### Adding CPU load to the cluster..."
echo "####################################################################"
MANIFESTS=promdata-offline/profiles/manifests

oc create -f $MANIFESTS/00-stress-ng-ns-sa.yaml -f $MANIFESTS/01-stress-ng-deployment-high-cpu-mem.yaml
echo "##### Sleeping 10mins for captures..."
sleep $Wait10mins

echo "####################################################################"
echo "##### Adding Key/Value load to the cluster..."
echo "####################################################################"
oc create -f $MANIFESTS/02-stress-ng-job-key-value-store.yaml
echo "##### Sleeping 5mins for captures..."
sleep $Wait5mins

echo "####################################################################"
echo "##### Adding password encryption load to the cluster..."
echo "####################################################################"
oc create -f $MANIFESTS/03-stress-ng-deployment-password-encryption.yaml
echo "##### Sleeping 5mins for captures..."
sleep $Wait5mins

echo "####################################################################"
echo "##### Removing CPU load from the cluster..."
echo "####################################################################"
oc delete -f $MANIFESTS/01-stress-ng-deployment-high-cpu-mem.yaml
echo "##### Sleeping 5mins for captures..."
sleep $Wait5mins

echo "####################################################################"
echo "##### Removing all geneerated load from the cluster..."
echo "####################################################################"
oc delete -f $MANIFESTS/03-stress-ng-deployment-password-encryption.yaml -f $MANIFESTS/02-stress-ng-job-key-value-store.yaml
oc delete -f $MANIFESTS/00-stress-ng-ns-sa.yaml

wait_for_stable_cluster

echo "####################################################################"
echo "##### Executing kube-burner node-density with timeout of 20minutes..."
echo "####################################################################"
kube-burner ocp node-density --gc --qps 100 --timeout 20m

wait_for_stable_cluster

echo "####################################################################"
echo "##### Executing kube-burner cluster-density-v2 with timeout of 20minutes..."
echo "####################################################################"
kube-burner ocp cluster-density-v2 --iterations 3 --gc --qps 100 --timeout 20m

wait_for_stable_cluster

echo "####################################################################"
echo "##### Sleeping 5mins for captures..."
echo "####################################################################"
sleep $Wait5mins

echo "####################################################################"
echo "##### Upgrading cluster..."
echo "####################################################################"
oc adm upgrade --to-latest

wait_for_stable_cluster

while true ; do 
    echo "####################################################################"
    echo "##### All task completed..."
    echo "After exiting kill all subprocesses of pid $CAPTURE_PID"
    pstree -apT $CAPTURE_PID
    pstree -pT $CAPTURE_PID
    echo "####################################################################"
    sleep 1
done