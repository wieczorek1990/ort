#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/config.sh

sudo rm ${dest}
sudo rm ${bin}/ortografia
sudo rm ${bin}/ortografia_server
