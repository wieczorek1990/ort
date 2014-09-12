#!/bin/bash
src=/media/`whoami`/green/ort
dest=~/ort
bin=/usr/local/bin

rm -rf $src/db/*
if [ "`ls -A $dest/db `" ]
then
    mv $dest/db/* $src/db/
fi
rm -rf $dest
cp -r $src ~
chmod +x $dest/ortografia
if [ "`readlink -n $bin/ortografia`" != $dest/ortografia ]
then
    sudo ln -fs $dest/ortografia $bin
fi