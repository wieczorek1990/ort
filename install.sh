#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${DIR}; source config.sh; cd -

# Backup DB's
rm -rf ${src}/db/*
if [ -d ${dest}/db ]
then
    if [ "`ls -A -I .gitignore ${dest}/db`" ]
    then
        cp ${dest}/db/* ${src}/db/
    fi
fi
# Uninstall
bash ${DIR}/uninstall.sh
# Install
sudo cp -r ${src} ${dest}
sudo chmod -R 755 ${dest}
sudo chown -R ${user}:${user} ${dest}
# Shortcuts
client='#!/bin/bash\nruby '${dest}'/src/ort.rb'
sudo bash -c "echo -e '${client}' > ${bin}/ortografia"
sudo chmod +x ${bin}/ortografia
if [ "$1" == 'server' ]
then
    server='#!/bin/bash\nruby '${dest}'/src/server.rb'
    sudo bash -c "echo -e '${server}' > ${bin}/ortografia_server"
    sudo chmod +x ${bin}/ortografia_server
fi