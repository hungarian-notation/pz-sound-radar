#!/usr/bin/env bash

LUA_PATHS=("lua5.1")

TEST_PATH="./src/hfsound/main/media/lua/tests"
TEST_CLASSPATH_1=`realpath --relative-to="$TEST_PATH" ".dist/Contents/mods/hfsound/42.17/media/lua/client"`
TEST_CLASSPATH_2=`realpath --relative-to="$TEST_PATH" ".dist/Contents/mods/hfsound/42.17/media/lua/shared"`

  
TEST_COMMAND=('-e' "print(\"`echo -e "\e[38;5;244m"`\")")
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
    echo -e -n "\e[38;5;244m"
    pushd $1 > /dev/null 
    
    LUA_COLORS=1 ${@:2} 

    popd > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31mCommand failed with error code $?"
    fi
}

for LUA_PATH in "${LUA_PATHS[@]}"; do
    echo -e "\e[0m# \e[1;37mUsing \e[0;33m$LUA_PATH\e[0m "
    
    # TEST_COMMAND_HERE=("${TEST_COMMAND[@]}" "-e" "load_tests('$TEST_FILE');")

    execute_tests $TEST_PATH $LUA_PATH ${TEST_COMMAND[@]}
    echo -e "\e[0m"
done