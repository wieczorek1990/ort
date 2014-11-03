#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $DIR; source config.sh; cd - > /dev/null

sudo rm -rf ${dest}
sudo rm -f ${bin}/ort
sudo rm -f ${bin}/ort_server
