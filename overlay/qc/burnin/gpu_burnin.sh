#!/bin/bash

if [ -f /tmp/gpu_result.txt ];then
	rm /tmp/gpu_result.txt
fi

echo pass >/tmp/gpu_qc.txt

glmark2 --run-forever --size 120x120 --reuse-context
