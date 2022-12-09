#!/bin/bash

testFailure(){
    $2 > /dev/null
    state=$?
    if [ $state -eq 0 ]; then
        echo "Failed: $1 | Exptected state: 1 got $state"
        exit 
    else 
        echo "Success: $1"
    fi
}

testSuccess() {
    $2 > /dev/null
    state=$?
    if [ $state -ne 0 ]; then
        echo "Failed: $1 | Exptected state: 0 got $state"
        exit 
    else 
        echo "Success: $1"
    fi
}

testFailure "Test apply normal without output" "../terraform-ext.sh -c -m apply -o"
testFailure "Test abort on missing mode" "../terraform-ext.sh -c"

testFailure "Test plan abort on invalid chars in place holder" '../terraform-ext.sh -c -m plan -p "\test" -r master'
testSuccess "Test plan with replace" '../terraform-ext.sh -c -m plan -p "test" -r master'
testSuccess "Test plan normal" "../terraform-ext.sh -c -m plan"
testSuccess "Test plan normal with output" "../terraform-ext.sh -c -m plan -o"

testSuccess "Test apply normal with output" "../terraform-ext.sh -c -m apply -o"
testSuccess "Test apply normal with replace" "../terraform-ext.sh -c -m apply -p test_placeholder -r master"

testSuccess "Test init normal " "../terraform-ext.sh -m init -c"

testSuccess "Test destroy normal " "../terraform-ext.sh -m destroy"

testSuccess "Test validate normal" "../terraform-ext.sh -m validate"
testSuccess "Test validate normal with replace" "../terraform-ext.sh -m validate -p test_placeholder -r master"


###########################
# Cleanup
###########################
rm terraform.plan