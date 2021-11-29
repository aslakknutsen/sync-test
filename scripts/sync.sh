#!/bin/bash

set -euo pipefail

ID=${PATCH_ID}

#TARGET_REPO=git@github.com:aslakknutsen/sync-test.git
#TARGET_BRANCH=main_downstream
TARGET_DIR=$(pwd)/${TARGET_DIR}
#SOURCE_REPO=git@github.com:aslakknutsen/sync-test.git
#SOURCE_BRANCH=main_upstream
SOURCE_DIR=$(pwd)/${SOURCE_DIR}
#PATCH_REPO=git@github.com:aslakknutsen/sync-test.git
#PATCH_BRANCH=patches
PATCH_DIR=$(pwd)/${PATCH_DIR}

# Basic operation
cd ${TARGET_DIR}

## Add remote source repo
git remote add source ${SOURCE_DIR}
git fetch source

## Start patch process

git checkout ${TARGET_BRANCH} # optional create new branch if this is a release tag/branch
git checkout -b patch_update_${ID}
git reset --hard source/${SOURCE_BRANCH}
MAIN_REF=$(git rev-parse HEAD)

for patch in $(ls -d $PATCH_DIR/*.patch)
do
    set +e ## turn off exit on error to capture git am failure.. any other way?
    apply_status="$(git am $patch -3 2>&1)"
    git_am_exit=$?
    set -e

    if [ $git_am_exit -ne 0 ];
    then
        err_diff=$(git am --show-current-patch=diff)
        git push origin patch_update_${ID}

        cat << EndOfMessage
Failed to update ${patch} on ${MAIN_REF}

Message:
${apply_status}

Diff:
${err_diff}

To recreate:
git checkout ${TARGET_REPO} patch_update_${ID} && git apply ${patch}

Fix conflict, commit and push to patch_update_${ID}
EndOfMessage

        exit -50
    fi
done

git checkout ${TARGET_BRANCH}
git reset --hard patch_update_${ID}
git push origin ${TARGET_BRANCH} --force
#echo git push origin :patch_update_${ID}