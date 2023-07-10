#!/bin/bash
# CREDITS:
#   Adapted from documentation at https://access.redhat.com/solutions/5482971 

DATA_DIR=metrics-4hrs
mkdir -p ${PWD}/${DATA_DIR}

# Get the Block ULID for the time series metrics from the last 4hrs 
TSDBLOCK=$(oc exec -n openshift-monitoring prometheus-k8s-0 -- promtool tsdb list -r /prometheus | tail -n2 | cut -f1 -d' ' )

for i in ${TSDBLOCK} ; do
    oc cp -n  openshift-monitoring prometheus-k8s-0:/prometheus/$i -c prometheus  ${DATA_DIR}/$i
done

# Create archive with data
tar zcvf prometheus-db-4hrs.tar.gz ${DATA_DIR}
