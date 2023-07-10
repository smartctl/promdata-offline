#!/bin/bash
set -e      # enable exit-on-error

# read env variables and assign defaults if not defined
STRESS_VM_BYTES="${MEMPERSTRESS:-500m}"
STRESS_TIMEOUT="${TIMEOUT:-10s}"
STRESS_NUMWORKERS="${STRESSWORKERS:-1}"
STRESS_PROFILE="${STRESSPROFILE:-""}"
STRESS_CYCLES="${CYCLES:-1}"
STRESS_RANDCYCLES="${RANDCYCLESPAUSE:-5}"

arg="${1:-$STRESS_PROFILE}"

if [[ "$arg" == "" ]]; then
    echo "Plesae sepecify the profile mode"
    echo "Usage: ${0} <profile-name>"
    echo "eg: ${0} profile1"
    exit 2
fi

set +e      # disable exit-on-error

random_pause () {

    if [[ "$STRESS_CYCLES" == +([[:digit:]]) ]]; then
        tpause=$(( $RANDOM % "$STRESS_RANDCYCLES" + 1 ))
    else
        tpause=5
    fi

    sleep $tpause
}

# Description of the flags option used in the profiles (from stress-ng --help)
# -r N, --random N      start N random workers
# -c N, --cpu N         start N workers that perform CPU only loading
# -m N, --vm N          start N workers spinning on anonymous mmap
# --vm-bytes N          allocate N bytes per vm worker (default 256MB)
# --vm-keep             redirty memory instead of reallocating
# --vmstat S            show memory and process statistics every S seconds
# -t N, --timeout T     timeout after T seconds
# --judy N              start N workers that exercise a judy array search
# --crypt N             start N workers performing password encryption
# --metrics-brief       enable metrics and only show non-zero results
# --cyclic N            start N cyclic real time benchmark stressors
# --cyclic-policy P     used rr or fifo scheduling policy


INX=0
echo "########## Running $arg profile for $STRESS_CYCLES cycles"
while [[ "$STRESS_CYCLES" -eq -1 ]] || [[ "$STRESS_CYCLES" -gt $INX ]]; do 

    INX=$(( $INX + 1 ))
    echo "******* CYCLE NUM=$INX"

    if [[ "$arg" ==  "high-cpu-mem" ]]; then

        stress-ng \
            --oomable --vm-keep -v \
            --vmstat 1 --temp-path /tmp \
            --vm-bytes ${STRESS_VM_BYTES} \
            -t ${STRESS_TIMEOUT} \
            -m ${STRESS_NUMWORKERS} \
            -c ${STRESS_NUMWORKERS} 

    elif [[ "$arg" ==  "key-value-store" ]]; then

        # execute Judy stress test
        # https://en.wikipedia.org/wiki/Judy_array
        stress-ng \
            --oomable --vm-keep -v \
            --vmstat 1 --temp-path /tmp \
            --vm-bytes ${STRESS_VM_BYTES} \
            -t ${STRESS_TIMEOUT} \
            --judy ${STRESS_NUMWORKERS}

    elif [[ "$arg" ==  "password-encryption" ]]; then

        # execute password encryption stress test
        stress-ng \
            --oomable --vm-keep -v \
            --vmstat 1 --temp-path /tmp \
            --vm-bytes ${STRESS_VM_BYTES} \
            -t ${STRESS_TIMEOUT} \
            --crypt ${STRESS_NUMWORKERS}

    elif [[ "$arg" ==  "low-latency" ]]; then

        # execute low latency stress test
        # Note: Use with real-time Linux Kernels to simulate Telco workload (e.g. 5G DU)
        stress-ng \
            --oomable --vm-keep -v \
            --vmstat 1 --temp-path /tmp \
            --vm-bytes ${STRESS_VM_BYTES} \
            -t ${STRESS_TIMEOUT} \
            --cyclic ${STRESS_NUMWORKERS} \
            --cyclic-policy fifo \
            --metrics-brief

    else

        echo "ERROR: Unknown profile ${arg}."
        exit 2

    fi

    random_pause 
done

echo "########## Entrypoint execution completed."
exit 0