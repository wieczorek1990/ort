#!/bin/bash
rm -rf ~/ort
cp -r /media/`whoami`/green/ort ~
chmod +x ~/ort/ortografia
sudo ln -fs ~/ort/ortografia /usr/local/bin
