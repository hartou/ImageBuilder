#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# This script builds Docker Images for all stacks on Azure App Service on Linux.
# --------------------------------------------------------------------------------------------

set -e


# Directory for Generated Docker Files
declare -r SYSTEM_ARTIFACTS_DIR="$1"
declare -r APP_SVC_BRANCH_PREFIX="$2"           # appsvc, appsvctest
declare -r CONFIG_DIR="$3"
declare -r PIPELINE_BUILD_NUMBER="$4"
declare -r STACK="$5"
declare -r TEST_IMAGE_REPO_NAME="appsvcdevacr.azurecr.io"
declare -r ACR_BUILD_IMAGES_ARTIFACTS_FILE="$SYSTEM_ARTIFACTS_DIR/builtImages.txt"


function buildAndTagStage()
{
	local dockerFile="$1"
	local stageName="$2"
	local stageTagName="$ACR_PUBLIC_PREFIX/$2"

	echo
	echo "Building stage '$stageName' with tag '$stageTagName'..."
	docker build --target $stageName -t $stageTagName $ctxArgs $BASE_TAG_BUILD_ARGS -f "$dockerFile" .
}

function buildDockerImage() 
{
    if [ -f "$CONFIG_DIR/${STACK}VersionTemplateMap.txt" ]; then
        while IFS=, read -r STACK_VERSION STACK_VERSION_TEMPLATE_DIR STACK_TAGS || [[ -n $STACK_VERSION ]] || [[ -n $STACK_VERSION_TEMPLATE_DIR ]] || [[ -n $STACK_TAGS ]]
        do
            echo "Stack Tag is ${STACK_TAGS}"
            IFS='|' read -ra STACK_TAGS_ARR <<< "$STACK_TAGS"
            for TAG in "${STACK_TAGS_ARR[@]}"
            do
                local buildImageTagUpperCase="${TEST_IMAGE_REPO_NAME}/${STACK}:${TAG}_${PIPELINE_BUILD_NUMBER}"
                local buildImageTag="${buildImageTagUpperCase,,}"
                local appSvcDockerfilePath="${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}/Dockerfile" 
                echo "Listing artifacts dir"
                ls "${SYSTEM_ARTIFACTS_DIR}"
                echo "Listing stacks dir"
                ls "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}"
                cd "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/${STACK_VERSION}"
                echo
                echo "Building test image with tag '$buildImageTag' and file $appSvcDockerfilePath..."
                echo docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .
                docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .
                docker push $buildImageTag
                echo $buildImageTag > $SYSTEM_ARTIFACTS_DIR/builtImageList
            done
        done < "$CONFIG_DIR/${STACK}VersionTemplateMap.txt"
    else
        local buildImageTagUpperCase="${TEST_IMAGE_REPO_NAME}/${STACK}:${PIPELINE_BUILD_NUMBER}"
        local buildImageTag="${buildImageTagUpperCase,,}"
        local appSvcDockerfilePath="${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/kudu/Dockerfile" 
        echo "Listing artifacts dir"
        ls "${SYSTEM_ARTIFACTS_DIR}"
        echo "Listing stacks dir"
        ls "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/kudu"
        cd "${SYSTEM_ARTIFACTS_DIR}/${STACK}/GitRepo/kudu"
        echo
        echo "Building test image with tag '$buildImageTag' and file $appSvcDockerfilePath..."
        echo docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .
        docker build -t "$buildImageTag" -f "$appSvcDockerfilePath" .
        docker push $buildImageTag
        echo $buildImageTag > $SYSTEM_ARTIFACTS_DIR/builtImageList
    fi
}

buildDockerImage
