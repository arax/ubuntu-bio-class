#!/bin/bash

# -------------------------------------------------------------------------- #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

source $(dirname $0)/../common/env.sh

# Paths
PASS_FILE="/root/ubuntu-bio-class.pass"
LOCAL_SHARED="/data/shared"
CONTAINER_SHARED="/data/shared"
LOCAL_PERSISTENT="/data/permanent"
CONTAINER_PERSISTENT="/home/$USERNAME"
LOCAL_AUTH_KEYS_FILES="/root/.ssh/authorized_keys $HOME/.ssh/authorized_keys"
CONTAINER_AUTH_KEYS_FILE_BASE="$LOCAL_PERSISTENT/.ssh"
CONTAINER_AUTH_KEYS_FILE="$CONTAINER_AUTH_KEYS_FILE_BASE/authorized_keys"

# Docker
DOCKER_APPLIANCE="arax/ubuntu-bio-class"

# Read password from a file, if not already set and the file is available
if [ -z "$PASSWORD" ] && [ -f "$PASS_FILE" ] ; then
    PASSWORD=$(cat "$PASS_FILE" | tr -d '\n')
fi

# Move .ssh/authorized_keys, if necessary
for LOCAL_AUTH_KEYS_FILE in $LOCAL_AUTH_KEYS_FILES ; do
    if [ -f "$LOCAL_AUTH_KEYS_FILE" ] && [ ! -f "$CONTAINER_AUTH_KEYS_FILE" ] ; then
        mkdir -p "$CONTAINER_AUTH_KEYS_FILE_BASE"
        chmod 755 "$CONTAINER_AUTH_KEYS_FILE_BASE"

        cp "$LOCAL_AUTH_KEYS_FILE" "$CONTAINER_AUTH_KEYS_FILE"
        chmod 600 "$CONTAINER_AUTH_KEYS_FILE"
        break
    fi
done

# Run ubuntu-bio-class, reinitialize after failure (cannot use --restart=always)
#
# Forwarding:
#  => 22   (SSH)
#  => 8787 (RStudio-server)
#
# Mounts:
#  => $LOCAL_SHARED     to $CONTAINER_SHARED     (ro)
#  => $LOCAL_PERSISTENT to $CONTAINER_PERSISTENT (rw)
while true ; do
    /usr/bin/docker run --rm \
                        -p 2222:22 -p 8787:8787 \
                        -v "$LOCAL_SHARED":"$CONTAINER_SHARED":ro -v "$LOCAL_PERSISTENT":"$CONTAINER_PERSISTENT" \
                        -e "PASSWORD=$PASSWORD" \
                        "$DOCKER_APPLIANCE"
    sleep 5 # prevent quick restarts
done
