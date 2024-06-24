#!/bin/bash

if [ -f /tmp/uart_qc_$1.txt ];then
        rm /tmp/uart_qc_$1.txt
fi

if [ -f /tmp/uart_tmp_$1.txt ];then
        rm /tmp/uart_tmp_$1.txt
fi

echo "fail" > /tmp/uart_qc_$1.txt
test_str=123

uart_path=/dev/$1
echo "uart_path=$uart_path"
stty -F $uart_path -echo -onlcr
cat $uart_path > /tmp/uart_tmp_$1.txt &

while true
do
	cat $uart_path > /tmp/uart_tmp_$1.txt &
	sleep 2
	# echo string
	echo $test_str > $uart_path
	sleep 2
	fuser -k /bin/cat > /dev/null 2>&1

	cat /tmp/uart_tmp_$1.txt |grep -a $test_str
	if [ $? == 0  ];then
		echo "pass" > /tmp/uart_qc_$1.txt
	else
		echo "fail" > /tmp/uart_qc_$1.txt
	fi
	> /tmp/uart_tmp_$1.txt
done

rm /tmp/uart_tmp_$1.txt

