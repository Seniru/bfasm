test() {
    cmd=$1
    expected=$2
    actual=$(sh $cmd)

    if [ "$expected" = "$actual" ];
    then
        echo -n "."
    else
        echo "Expected: $expected Actual: $actual"
    fi
}

echo "Test #1 "

test "bf hello-world.bf" "Hello World!"
test "bf arithmetic.bf" "8\n2\n8\n4"

