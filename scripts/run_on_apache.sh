#!/bin/bash

set -e
set -u

WHICHBIN=$1
DIR=$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))
source ${DIR}/mcsema_common.sh
source ${DIR}/env.sh

sanity_check

export TVHEADLESS=1
TARGET=apache

WORKSPACE=$(mktemp -d --tmpdir=./ ${TARGET}_XXXX)
export IDALOG=${WORKSPACE}/logfile_${TARGET}.txt
rm -f ${IDALOG} ${WHICHBIN}_out.exe ${WHICHBIN}.cfg ${WHICHBIN}.bc ${WHICHBIN}_opt.bc

echo "IDA Binary: ${IDA}"
echo "${TARGET} binary: ${WHICHBIN}"
echo "External definition files in: ${STD_DEFS}"
echo "Runtime files: ${RUNTIME_PATH}"
echo ""
echo "Workspace directory: ${WORKSPACE}" 
echo "IDA Log: ${IDALOG}"

recover_cfg ${WHICHBIN} ${WORKSPACE}/${TARGET}.cfg

convert_to_bc ${WORKSPACE}/${TARGET}.cfg ${WORKSPACE}/${TARGET}.bc

optimize_bc ${WORKSPACE}/${TARGET}.bc ${WORKSPACE}/${TARGET}_opt.bc

link_amd64_callback ${WORKSPACE}/${TARGET}_opt.bc ${WORKSPACE}/${TARGET}_linked.bc

call_llc ${WORKSPACE}/${TARGET}_linked.bc ${WORKSPACE}/${TARGET}.o 

LIBDIR=$(dirname ${WHICHBIN})/../lib

echo "Relinking with dependent libraries (${WORKSPACE}/${TARGET}_out.exe) (libs: ${LIBDIR})"
${CC} -I${DRIVER_PATH} -L${LIBDIR} -m64 -ggdb -o ${WORKSPACE}/${TARGET}_out.exe ${DRIVER_PATH}/httpd_linux_amd64.c ${WORKSPACE}/${TARGET}.o -lcrypt -lapr-1 -laprutil-1 -lpcre

echo "Run with:"
echo "LD_PRELOAD=${LIBDIR} ${WORKSPACE}/${TARGET}_out.exe"
