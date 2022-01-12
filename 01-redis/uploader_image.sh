#!/bin/bash
LOGDISABLE=1

echo "[ INFO ] Start image uploader script...."
img="$(cat avatar.jpg | base64 -w 0)"

function clean {
	[[ -z "$LOGDISABLE" ]] && echo "[ INFO ] Start clean"
	redis-cli KEYS "user:*" | xargs redis-cli DEL > /dev/null
	[[ -z "$LOGDISABLE" ]] && echo "[ INFO ] Clean complete"
}

function generate {
	# Clean generated file
	> generated/generated.txt
	for ((i = 1; i < END+1; i++)); do
		echo "SET user:${i} ${img}" >> generated/generated.txt
	done
}

function upload {
	cat generated/generated.txt | redis-cli --pipe > /dev/null
}

# Entry point
clean

echo "Time for upload 1_000 string row"
echo "--------------------------"
END=1000
generate
time upload
echo "--------------------------"
echo ""

echo "Time for upload 10_000 string row"
END=10000
generate
time upload
echo "--------------------------"
echo ""

echo "Time for upload 100_000 string row"
END=100000
generate
time upload
echo "--------------------------"
echo ""

echo "Time for upload 1_000_000 string row"
END=500000
generate
time upload
echo "--------------------------"
echo ""

echo "[ INFO ] Script end"




