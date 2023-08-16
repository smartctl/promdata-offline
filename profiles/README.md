
## Load Generation

- Using `kube-burner`
```bash
kube-burner ocp node-density --gc --qps 100 --timeout 20m

kube-burner ocp node-density-heavy --gc --qps 100 --timeout 20m

kube-burner ocp cluster-density --iterations 3 --gc --qps 100 --timeout 20m

kube-burner ocp cluster-density-v2 --iterations 1 --gc --qps 100 --timeout 20m

kube-burner ocp cluster-density-v2 --iterations 3 --gc --qps 100 --timeout 30m
```

# Total number of series

```bash
# Number of tsdb entries per Prometheus instance
sum by (pod) (prometheus_tsdb_head_series)

# Total number of tsdb entries across Prometheus instaces
openshift:prometheus_tsdb_head_series:sum
```
