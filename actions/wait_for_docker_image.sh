#!/bin/bash
set -e
ORG=$1
IMAGE=$2
VERSION=$3
TRIES=$4
DELAY=$5
 if [[ -z "${ORG}" || -z "${IMAGE}" || -z "${VERSION}" ]]; then
    echo "ERROR: Missing required parameter"
    echo "Usage: $0 ORG PROJECT VERSION"
    exit 1
fi
echo "https://hub.docker.com/v2/repositories/${ORG}/${IMAGE}/tags"
function docker_tag_exists() {
    URI="https://hub.docker.com/v2/repositories/${ORG}/${IMAGE}/tags"
    curl --silent --fail -lSL ${URI} | grep \"${VERSION}\" >/dev/null
}
 i=0
while ! docker_tag_exists "${ORG}/${IMAGE}" $VERSION;
do
    if (( ${TRIES} == 0 )); then
        sleep ${DELAY}
        continue
    fi
    if (( ++i < ${TRIES} )); then
        sleep ${DELAY}
    else
        echo "ERROR: Failed to find image ${ORG}/${IMAGE}:${VERSION} within requested time."
        exit 1
    fi
done
 echo "SUCCESS!"