#!/bin/bash

amixer cset numid=20,iface=MIXER,name='Capture Polarity' 3 > /dev/null 2>&1
amixer cset numid=32,iface=MIXER,name='Left PGA Mux' 1 > /dev/null 2>&1
amixer cset numid=33,iface=MIXER,name='Right PGA Mux' 1 > /dev/null 2>&1
