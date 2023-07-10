# Preparing a Fedora 38

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
