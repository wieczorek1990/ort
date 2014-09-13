#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${DIR}/config.sh

sudo rm -rf ${dest}
sudo rm -f ${bin}/ortografia
sudo rm -f ${bin}/ortografia_server
