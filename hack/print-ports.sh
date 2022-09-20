#!/usr/bin/env bash

[ ! -z "$SHARINGIO_PAIR_DISABLE_SVC_INGRESS_BIND_RECONCILER" ] && exit 0

KUBE_CONTEXTS="$(kubectl config view -o yaml | yq e .contexts[].name -P -)"
if echo "${KUBE_CONTEXTS}" | grep -q 'in-cluster'; then
    KUBE_CONTEXT="in-cluster"
elif echo "${KUBE_CONTEXTS}" | grep -q "kubernetes-admin@${SHARINGIO_PAIR_NAME}"; then
    KUBE_CONTEXT="kubernetes-admin@${SHARINGIO_PAIR_NAME}"
fi
K8S_MINOR_VERSION="$(kubectl --context "$KUBE_CONTEXT" version --client=false -o=json 2> /dev/null | jq -r '.serverVersion.minor' | tr -dc '[0-9]')"
export SHARINGIO_PAIR_BASE_DNS_NAME=${SHARINGIO_PAIR_BASE_DNS_NAME_SVC_ING_RECONCILER_OVERRIDE:-$SHARINGIO_PAIR_BASE_DNS_NAME}

echo "Watching for processes listening on all interfaces..."

while true; do
    listening=$(ss -tunlp 2>&1 | awk '{print $1 " " $5 " " $7}' | grep -E ':[0-9]' | grep -E '(\*|0.0.0.0):' || true)
    svcNames=""

    while IFS= read -r line; do
        export protocol=$(echo ${line} | awk '{print $1}' | grep -o '[a-z]*' | tr '[:lower:]' '[:upper:]')
        export portNumber=$(echo ${line} | awk '{print $2}' | cut -d ':' -f2 | grep -o '[0-9]*')
        export pid=$(echo ${line} | sed 's/.*pid=//g' | sed 's/,.*//g')
        processName=$(echo ${line} | awk '{print $3}' | cut -d '"' -f2)
        if [ -z "$processName" ]; then
            continue
        fi
        overrideHost=$(cat /proc/$pid/environ | tr '\0' '\n' | grep SHARINGIO_PAIR_SET_HOSTNAME | cut -d '=' -f2)

        export name=$processName
        if [ -n "$overrideHost" ]; then
          export name=$overrideHost
        fi
        export svcName="$name"

        export portNumberExpose="${portNumber}"
        if [ $portNumber -lt 1000 ]; then
          export portNumberExpose="1${portNumber}"
        fi
        export hostName="$svcName.$SHARINGIO_PAIR_BASE_DNS_NAME"

        echo "${svcName} ${hostName} ${portNumber} ${pid}"
        if [ ! "$protocol" = "TCP" ]; then
            continue
        fi

        svcNames="$svcName $svcNames"
    done < <(echo "$listening")

    sleep 2s
done