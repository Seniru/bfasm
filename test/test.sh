#! /bin/bash

all=0
failed=0

test() {
    all=$((all+1))
    cmd=$1
    expected=$2
    expected+=$'\nProgram completed!'
    actual=$($cmd | tr -d '\0')

    if [ "$expected" = "$actual" ];
    then
        echo -n "."
    else
        echo -e "\nTest case failed!"
        diff --color=always -C2 -LExpected -LActual <(echo "$expected") <(echo "$actual")
        failed=$((failed+1))
    fi
}

echo "Test #1"

test "./bf ./test/inc-dec.bf" $'\005\002'
test "./bf ./test/left-right.bf" $'\005\003\005'
test "./bf ./test/loop.bf" $'\005\001\001\002\003\004\005'
test "./bf ./test/nested-loops.bf" $'\024' # 20 base 10 = 24 base 8
test "./bf ./test/simple-if.bf" "10"

echo
echo "Test #2"

test "./bf ./test/hello-world.bf" "Hello World!"
test "./bf ./test/arithmetic.bf" $'8\n2\n8\n4'

echo -en "\n\nTests done. "
echo -en "$failed tests failed. "
echo -en "Test score: $(($all-$failed))/$all\n"

if [ $failed -gt 0 ];
then
    exit 1
else
    exit 0
fi
