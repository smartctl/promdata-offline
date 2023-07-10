# Prometheus with offline metrics

## Capturing metrics

Execute the capturing script from a CLI already authenticated to access the cluster

```bash
# execute script to cappture the last 4hrs
./dump-prometheus-4hrs.sh
```

## Using Offline Prometheus for interacting with metrics

```bash
# Create empty prometheus configuration file
mkdir -p /tmp/prometheus-config
touch /tmp/prometheus-config/prometheus.yml

# specify path for metrics
METRICSDIR=./metrics-4hrs
```

```bash
# Run prometheus isntance 
podman run -tid --rm -p 9000:9000/tcp \
    --name offline-prometheus \
    -v /tmp/prometheus-config:/prometheus-config:Z \
    -v ${METRICSDIR}:/prometheus:Z  \
    --user root \
    quay.io/prometheus/prometheus \
    --config.file=/prometheus-config/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --web.enable-admin-api \
    --storage.tsdb.retention.time=365d \
    --web.listen-address=0.0.0.0:9000 \
    --web.external-url=http://${HOSTNAME}:9000/
```

- Validate min/max time range of the metrics
    ```bash
    # Using the promtool
    $ podman exec -ti  offline-prometheus promtool tsdb list -r /prometheus
    BLOCK ULID                  MIN TIME                       MAX TIME                       DURATION      NUM SAMPLES  NUM CHUNKS   NUM SERIES   SIZE
    01H4G8YDPS4PDVDW52FC6808HA  2023-07-04 08:00:01 +0000 UTC  2023-07-04 10:00:00 +0000 UTC  1h59m58.266s  49333744     416777       216692       155MiB142KiB605B
    01H4GFT3ZPB6MR4BGM05KX6BD5  2023-07-04 10:00:01 +0000 UTC  2023-07-04 12:00:00 +0000 UTC  1h59m58.277s  49361968     416686       216418       155MiB671KiB110B
    ```
    ```bash
    # Obtaining the range from the container logs
    $ podman logs offline-prometheus | grep mint
    ts=2023-07-10T17:01:57.794Z caller=repair.go:56 level=info component=tsdb msg="Found healthy block" mint=1688457601734 maxt=1688464800000 ulid=01H4G8YDPS4PDVDW52FC6808HA
    ts=2023-07-10T17:01:57.795Z caller=repair.go:56 level=info component=tsdb msg="Found healthy block" mint=1688464801723 maxt=1688472000000 ulid=01H4GFT3ZPB6MR4BGM05KX6BD5
    ```
- To interact with the metrics we have to specify the range.
    - In the UI you must specify the "Evaluation Time"
    - In the API the start/end times

- Using the Prometheus UI
    - Connect to `http://${HOSTNAME}:9000/` to access the prometheu UI
    - Prometheus > Table > "Evaluation Time" and select day and time within the available range
    - Execute `prometheus_tsdb_head_series` to get the number of TSDB entries on the specifc time range

- Using the API interactions with `curl`
    ```bash
    # define start & end times
    START_TIME="2023-07-04T08:00:01.0000Z"
    END_TIME="2023-07-04T12:00:00.0000Z"
    # define urlencoded promql
    PROMQL="prometheus_tsdb_head_series"
    ```
    ```bash
    # Metrics on a time range
    curl "http://${HOSTNAME}:9000/api/v1/query_range?query=${PROMQL}&step=1m&start=${START_TIME}&end=${END_TIME}"
    # Metrics on at a specific time
    curl "http://${HOSTNAME}:9000/api/v1/query?query=${PROMQL}&time=${END_TIME}"
    ```

## Additional Information

### Aditional Tools
- Convert unix timestamp: https://www.epochconverter.com


### Credits
The original sources for the utils:
* [script to dump of the cluster Prometheus data](https://github.com/openshift/runbooks/blob/master/alerts/cluster-kube-apiserver-operator/ExtremelyHighIndividualControlPlaneCPU.md)
* Based on documentation from https://access.redhat.com/solutions/5482971

