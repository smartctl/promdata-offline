
#!/usr/bin/env bash
# dump of the cluster prometheus data

# CREDIT: Original source of script (adapted)
#   https://github.com/openshift/runbooks/blob/master/alerts/cluster-kube-apiserver-operator/ExtremelyHighIndividualControlPlaneCPU.md

function queue() {
  local TARGET="${1}"
  shift
  local LIVE
  LIVE="$(jobs | wc -l)"
  while [[ "${LIVE}" -ge 45 ]]; do
    sleep 1
    LIVE="$(jobs | wc -l)"
  done
  echo "${@}"
  if [[ -n "${FILTER:-}" ]]; then
    "${@}" | "${FILTER}" >"${TARGET}" &
  else
    "${@}" >"${TARGET}" &
  fi
}

ARTIFACT_DIR=metrics-all
mkdir -p $PWD/$ARTIFACT_DIR
echo "Snapshotting prometheus (may take 15s) ..."
queue ${ARTIFACT_DIR}/prometheus.tar.gz oc --insecure-skip-tls-verify exec -n openshift-monitoring prometheus-k8s-0 -- tar cvzf - -C /prometheus .
FILTER=gzip queue ${ARTIFACT_DIR}/prometheus-target-metadata.json.gz oc --insecure-skip-tls-verify exec -n openshift-monitoring prometheus-k8s-0 -- /bin/bash -c "curl -G http://localhost:9090/api/v1/targets/metadata --data-urlencode 'match_target={instance!=\"\"}'"
