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

test "./bf --file ./test/inc-dec.bf" $'\005\002'
test "./bf --file ./test/left-right.bf" $'\005\003\005'
test "./bf --file ./test/loop.bf" $'\005\001\001\002\003\004\005'
test "./bf --file ./test/nested-loops.bf" $'\024' # 20 base 10 = 24 base 8
test "./bf --file ./test/simple-if.bf" "10"
test "./test/input.bf.sh" $'\nProgram input: adf'

echo
echo "Test #2"

test "./bf --file ./test/hello-world.bf" "Hello World!"
test "./bf --file ./test/arithmetic.bf" $'8\n2\n8\n4'

echo -en "\n\nTests done. "
echo -en "$failed tests failed. "
echo -en "Test score: $(($all-$failed))/$all\n"

if [ $failed -gt 0 ];
then
    exit 1
else
    exit 0
fi
