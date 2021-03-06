#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $DIR; source config.sh; cd - > /dev/null

bash $DIR/uninstall.sh
sudo cp -r "$src" "$dest"
client="#!/bin/bash\nruby ${dest}/src/ort.rb"
sudo bash -c "echo -e '${client}' > ${bin}/ort"
sudo chmod +x "$bin/ort"
if [ "$1" == 'server' ]
then
  server="#!/bin/bash\nruby ${dest}/src/server.rb"
  sudo bash -c "echo -e '${server}' > ${bin}/ort_server"
  sudo chmod +x ${bin}/ort_server
fi