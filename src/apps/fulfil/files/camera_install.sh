#!/bin/bash
# This script is designed to run when a newly provisioned node first comes
# online. This script will setup networking, define the hostname, etc. which
# are unique to a given node.
set -x

bash ~/upload_cam_code.sh