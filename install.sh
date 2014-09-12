#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/config.sh

rm -rf ${src}/db/*
if [ -d ${dest}/db ]
then
    if [ "`ls -A -I .gitignore ${dest}/db`" ]
    then
        cp ${dest}/db/* ${src}/db/
    fi
fi
sudo rm -rf ${dest}
sudo cp -r ${src} ${dest}
sudo chmod -R 777 ${dest}
client='#!/bin/bash\nruby '${dest}'/src/ortografia.rb'
server='#!/bin/bash\nruby '${dest}'/src/server.rb'
sudo bash -c "echo -e '${client}' > ${bin}/ortografia"
sudo bash -c "echo -e '${server}' > ${bin}/ortografia_server"
sudo chmod +x ${bin}/ortografia
sudo chmod +x ${bin}/ortografia_server