#!/bin/bash
set -e

PROJECT=$2
VERSION=$3
FORK=$4
LOCAL_REPO=$5
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

if [[ ! -e "${CHANGELOG_FILE}" ]]; then
    >&2 echo "ERROR: Changelog ${CHANGELOG_FILE} does not exist."
    exit 1
fi

CHANGELOG_VERSION_MATCH=`grep "${VERSION} - " ${CHANGELOG_FILE} || true`
if [[ -z "${CHANGELOG_VERSION_MATCH}" ]]; then
    echo "Setting version in ${CHANGELOG_FILE} to ${VERSION}..."
    sed -i "s/^## In development/## ${RELEASE_STRING}/Ig" ${CHANGELOG_FILE}

    if [ "$PROJECT" = "antidote" ]; then
        sed -i "/${RELEASE_STRING}/i \## In development\n\n### Curriculum\n\n### Other\n\n" ${CHANGELOG_FILE}
    else
        sed -i "/${RELEASE_STRING}/i \## In development\n\n" ${CHANGELOG_FILE}
    fi
fi

MODIFIED=`git status | grep modified || true`
if [[ ! -z "${MODIFIED}" ]]; then
    git add ${CHANGELOG_FILE}
    git commit -qm "Update changelog info for release - ${VERSION}"
    git push origin master
fi

# CHECK IF BRANCH EXISTS
BRANCH_EXISTS=`git ls-remote --heads ${GIT_REPO} | grep refs/heads/${BRANCH} || true`

if [[ ! -z "${BRANCH_EXISTS}" ]]; then
    git checkout ${BRANCH}
else
    # Create release branch and tag
    echo "Creating new branch ${BRANCH}..."
    git checkout -b ${BRANCH} origin/master
fi



# CHECK IF TAG EXISTS
TAGGED=`git tag -l ${TAGGED_VERSION} || true`
if [[ -z "${TAGGED}" ]]; then
    # TAG RELEASE
    echo "Tagging release ${TAGGED_VERSION} for ${PROJECT}..."
    git tag -a ${TAGGED_VERSION} -m "Creating tag ${TAGGED_VERSION} for branch ${BRANCH}"
    git push origin ${TAGGED_VERSION}
    git push origin ${BRANCH}
else
    echo "Tag ${TAGGED_VERSION} already exists."
fi

# CLEANUP
cd ${CWD}
rm -rf ${LOCAL_REPO}
