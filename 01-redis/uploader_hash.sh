#!/bin/bash

echo "[ INFO ] Start Hash script uploader ...."

LOGDISABLE=1
function clean {
	[[ -z "$LOGDISABLE" ]] && echo "[ INFO ] Start clean"
	redis-cli KEYS "user:*" | xargs redis-cli DEL > /dev/null
	[[ -z "$LOGDISABLE" ]] && echo "[ INFO ] Clean complete"
}

function generate {
	# Clean generated file
	> generated/generated.txt
	for ((i = 1; i < END+1; i++)); do
		echo "HMSET user:${i} KEYFIRST value${i} KEYSECOND value${i} KEYTHIRD value${i}" >> generated/generated.txt
	done
}

function upload {
	cat generated/generated.txt | redis-cli --pipe > /dev/null
}

# Entry point
clean

echo "Time for upload 1_000 hash"
echo "--------------------------"
END=1000
generate
time upload
clean
echo "--------------------------"

echo ""
echo "Time for upload 10_000 hash"
END=10000
generate
time upload
# clean
echo "--------------------------"

echo ""
echo "Time for upload 100_000 hash"
END=100000
generate
time upload
clean
echo "--------------------------"

echo ""
echo "Time for upload 1_000_000 hash"
END=1000000
generate
time upload
clean
echo "--------------------------"

echo ""
echo "Time for upload 10_000_000 hash"
END=10000000
generate
time upload
clean
echo "--------------------------"


echo "[ INFO ] Script end"
