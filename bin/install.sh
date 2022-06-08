#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$DIR"; source config.sh; cd - > /dev/null

function make_executable_from_source() {
  source_name="$1"
  executable_name="$2"

  payload="#!/bin/bash\nruby ${dest}/src/${source_name}"
  sudo bash -c "echo -e '${payload}' > ${bin}/${executable_name}"
  sudo chmod +x "$bin/${executable_name}"
}

bash $DIR/uninstall.sh
sudo cp -r "$src" "$dest"
make_executable_from_source ort.rb "$ort_name"
if [ "$1" == 'server' ]
then
  make_executable_from_source server.rb "$ort_server_name"
fi
