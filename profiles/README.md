# Workload Profiles

## Building the stress-ng container

Preparing a Fedora 38

- Preparing a Fedora build machine
    ```bash
    # install dependencies
    dnf -y install podman jq

    ```
- Preparing a Fedora OpenShift client machine.
    Download OpenShift `oc` CLI from the [mirror](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/)
    ```bash
    # download the OpenShift client (assuming Linux on x86)
    curl -OL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
    # This includes the oc and kubectl CLI
    tar -xzf openshift-client-linux.tar.gz
    ```

## Load Generation with `kube-burner`

- Example of using `kube-burner` to generate load on a clusters (examples from kube-burner documentation)

    ```bash
    kube-burner ocp node-density --gc --qps 100 --timeout 20m

    kube-burner ocp node-density-heavy --gc --qps 100 --timeout 20m

    kube-burner ocp cluster-density --iterations 3 --gc --qps 100 --timeout 20m

    kube-burner ocp cluster-density-v2 --iterations 1 --gc --qps 100 --timeout 20m

    kube-burner ocp cluster-density-v2 --iterations 3 --gc --qps 100 --timeout 30m
    ```


## CREDITS

Each directory containing code or tools from external sources has a CREDITS.md file.