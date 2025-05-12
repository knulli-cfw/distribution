#!/bin/sh

cp /usr/share/evmapy/odcommander.keys /var/run/evmapy/event1.json

evmapy &

od-commander

killall -9 evmapy 
