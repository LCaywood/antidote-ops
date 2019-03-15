#!/usr/bin/env bash

GITHUB_TOKEN=$1
RELEASE_VERSION=$2

rm -rf /tmp/syringe
git clone --branch $RELEASE_VERSION https://github.com/nre-learning/syringe /tmp/syringe

docker run -v $/tmp/syringe:/go/src/github.com/nre-learning/syringe \
    antidotelabs/syringebuilder /compile_and_upload.sh $GITHUB_TOKEN $RELEASE_VERSION
