#!/bin/bash
set -e

PROJECT=$2
VERSION=$3
DOCKER_VERSION=$4
FORK=$5
LOCAL_REPO=$6
GIT_REPO="git@github.com:${FORK}/${PROJECT}.git"
SHORT_VERSION=`echo ${VERSION} | cut -d "." -f1-2`
# Using version for now. Each minor version gets its own branch.
BRANCH="release-v${VERSION}"
# BRANCH="release-v${SHORT_VERSION}"
TAGGED_VERSION="v${VERSION}"
CWD=`pwd`

git config --global user.email "abathur@networkrelibility.engineering"
git config --global user.name "abathur"

# GIT CLONE AND BRANCH
if [[ -z ${LOCAL_REPO} ]]; then
    CURRENT_TIMESTAMP=`date +'%s'`
    RANDOM_NUMBER=`awk -v min=100 -v max=999 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
    LOCAL_REPO="/tmp/${PROJECT}_${CURRENT_TIMESTAMP}_${RANDOM_NUMBER}"
fi

echo "Cloning ${GIT_REPO} to ${LOCAL_REPO}..."

if [ -d "${LOCAL_REPO}" ]; then
    rm -rf ${LOCAL_REPO}
fi

git clone ${GIT_REPO} ${LOCAL_REPO}

cd ${LOCAL_REPO}
echo "Currently at directory `pwd`..."

# SET VERSION AND DATE IN CHANGELOG ON MASTER
DATE=`date +%s`
RELEASE_DATE=`date +"%B %d, %Y"`
CHANGELOG_FILE="CHANGELOG.md"
RELEASE_STRING="${VERSION} - ${RELEASE_DATE}"
DASH_HEADER_CMD="printf '%.0s-' {1..${#RELEASE_STRING}}"
DASH_HEADER=$(/bin/bash -c "${DASH_HEADER_CMD}")

# CHECK IF BRANCH EXISTS
BRANCH_EXISTS=`git ls-remote --heads ${GIT_REPO} | grep refs/heads/${BRANCH} || true`

if [[ ! -z "${BRANCH_EXISTS}" ]]; then
    git checkout ${BRANCH}
else
    # Create release branch and tag
    echo "Creating new branch ${BRANCH}..."
    git checkout -b ${BRANCH} origin/master
fi

COMMIT_SHA=$(git rev-parse HEAD)
if [ "$PROJECT" = "antidote-web" ]; then
    docker build --build-arg COMMIT_SHA=$COMMIT_SHA -t antidotelabs/antidote-web:${DOCKER_VERSION} -f Dockerfile .
    docker push antidotelabs/antidote-web:${DOCKER_VERSION}
elif [ "$PROJECT" = "syringe" ]; then
	docker build -t antidotelabs/syringe:${DOCKER_VERSION} .
	docker push antidotelabs/syringe:${DOCKER_VERSION}
fi

# CLEANUP
cd ${CWD}
rm -rf ${LOCAL_REPO}
