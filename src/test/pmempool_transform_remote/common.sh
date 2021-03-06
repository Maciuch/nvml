#!/usr/bin/env bash
#
# Copyright 2017, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# pmempool_transform_remote/common.sh -- commons for pmempool transform tests
#                                        with remote replication
#
set -e

require_nodes 2

require_node_libfabric 0 $RPMEM_PROVIDER
require_node_libfabric 1 $RPMEM_PROVIDER

init_rpmem_on_node 0 1

require_node_log_files 0 pmemobj$UNITTEST_NUM.log
require_node_log_files 0 pmempool$UNITTEST_NUM.log

LOG=out${UNITTEST_NUM}.log
LOG_TEMP=out${UNITTEST_NUM}_part.log
rm -rf $LOG && touch $LOG
rm -rf $LOG_TEMP && touch $LOG_TEMP
rm_files_from_node 0 $LOG

LAYOUT=OBJ_LAYOUT
POOLSET_LOCAL_IN=poolset.in
POOLSET_LOCAL_OUT=poolset.out
POOLSET_REMOTE=poolset.remote
POOLSET_REMOTE1=poolset.remote1
POOLSET_REMOTE2=poolset.remote2
NODE_DIRS=($(get_node_dir 0) $(get_node_dir 1))

# CLI scripts for writing and reading some data hitting all the parts
WRITE_SCRIPT="pmemobjcli.write.script"
READ_SCRIPT="pmemobjcli.read.script"
copy_files_to_node 0 . $WRITE_SCRIPT
copy_files_to_node 0 . $READ_SCRIPT

DUMP_INFO_LOG="../pmempool info"
DUMP_INFO_SED="sed -e '/^Checksum/d' -e '/^Creation/d' -e '/^Previous replica UUID/d' -e '/^Next replica UUID/d'"

function dump_info_log() {
	local node=$1
	local poolset=$2
	local name=$3
	local ignore=$4

	local sed_cmd="$DUMP_INFO_SED"
	if [ -n "$ignore" ]; then
		sed_cmd="$sed_cmd -e '/^$ignore/d'"
	fi

	expect_normal_exit run_on_node $node "\"$DUMP_INFO_LOG $poolset | $sed_cmd > $name\""
}

function diff_log() {
	local node=$1
	local f1=$2
	local f2=$3

	expect_normal_exit run_on_node $node "\"[ -s $f1 ] && [ -s $f2 ] && diff $f1 $f2\""
}

