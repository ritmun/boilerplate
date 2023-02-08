#!/usr/bin/env bash

set -e

cmd=${0##*/}

usage() {
    cat <<EOF
Usage: $0 OPERATOR_NAME OSDE2E_CONVENTION_DIR
 
EOF
    exit -1
}

OPERATOR_NAME=$1
OSDE2E_CONVENTION_DIR=$2
REPO_ROOT=$(git rev-parse --show-toplevel)
HARNESS_DIR=$REPO_ROOT/osde2e

# Update operator name in templates
export OPERATOR_HYPHEN_NAME=$(echo "$OPERATOR_NAME"| sed 's/-/_/g')
export OPERATOR_PROPER_NAME=$(echo "$OPERATOR_NAME"| sed 's/-/ /g' |awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1')
export REPLACE_SPECNAME=${OPERATOR_PROPER_NAME} Test Harness
export REPLACE_FUNC=$(echo "$REPLACE_SPECNAME" | sed 's/ //g' )

mkdir $HARNESS_DIR
 

echo "
# THIS FILE IS GENERATED BY BOILERPLATE. DO NOT EDIT.
FROM registry.ci.openshift.org/openshift/release:golang-1.18 AS builder
    
ENV PKG=/go/src/github.com/openshift/${OPERATOR_NAME}/
WORKDIR \${PKG}\
    
COPY . .
    
FROM registry.access.redhat.com/ubi7/ubi-minimal:latest
    
COPY ./harness.test harness.test
    
ENTRYPOINT [ \"/harness.test\" ]" > $HARNESS_DIR/Dockerfile

echo "package osde2etests

import \"github.com/onsi/ginkgo/v2\"

var _ = ginkgo.Describe(\"$OPERATOR_NAME\", func() {
	//	 Add your tests 
})
" > ${HARNESS_DIR}/${OPERATOR_HYPHEN_NAME}_tests.go

echo "// THIS FILE IS GENERATED BY BOILERPLATE. DO NOT EDIT.
//go:build integration
// +build integration

package osde2etests

import (
	\"path/filepath\"
	\"testing\"
	. \"github.com/onsi/ginkgo/v2\"
	. \"github.com/onsi/gomega\"
)

const (
	testResultsDirectory = \"/test-run-results\"
	jUnitOutputFilename  = \"junit-example-addon.xml\"
)

// Test entrypoint. osde2e runs this as a test suite on test pod.
func $REPLACE_FUNC(t *testing.T) {
	RegisterFailHandler(Fail)

	suiteConfig, reporterConfig := GinkgoConfiguration()
	reporterConfig.JUnitReport = filepath.Join(testResultsDirectory, jUnitOutputFilename)
	RunSpecs(t, \"$REPLACE_SPECNAME\", suiteConfig, reporterConfig)

}
" > ${HARNESS_DIR}/${OPERATOR_HYPHEN_NAME}_runner_test.go