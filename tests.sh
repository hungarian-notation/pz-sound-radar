#!/usr/bin/env bash

LUA_PATHS=("lua5.1")

TEST_PATH="./src/hfsound/main/media/lua/tests"
TEST_CLASSPATH_1=`realpath --relative-to="$TEST_PATH" ".dist/Contents/mods/hfsound/42.17/media/lua/client"`
TEST_CLASSPATH_2=`realpath --relative-to="$TEST_PATH" ".dist/Contents/mods/hfsound/42.17/media/lua/shared"`

TEST_COMMAND=()
TEST_COMMAND+=('-e' "dofile('bootstrap.lua');")
TEST_COMMAND+=('-e' "bootstrap_path('$TEST_CLASSPATH_1/?.lua;$TEST_CLASSPATH_1/?/init.lua')")
TEST_COMMAND+=('-e' "bootstrap_path('$TEST_CLASSPATH_2/?.lua;$TEST_CLASSPATH_2/?/init.lua')")
TEST_COMMAND+=('-e' "dofile('lib.test.lua');")

TEST_FILES=()

while IFS= read -r -d '' file; do
    TEST_FILES+=("$file")
    TEST_COMMAND+=('-e' "load_tests('$file');")
    echo $file
done < <(cd $TEST_PATH && find . -name "*.test.lua" -not -name "lib.test.lua" -print0)

TEST_COMMAND+=("-e" "execute_tests()")

# echo " ${TEST_FILES[@]}"

function execute_tests() {
    pushd $1 > /dev/null 
    
    ${@:2} 

    popd > /dev/null
}

for LUA_PATH in "${LUA_PATHS[@]}"; do    
    # TEST_COMMAND_HERE=("${TEST_COMMAND[@]}" "-e" "load_tests('$TEST_FILE');")

    execute_tests $TEST_PATH $LUA_PATH ${TEST_COMMAND[@]}
done