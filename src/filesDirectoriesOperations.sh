#!/bin/bash
# Author: José M. C. Noronha

function moveAllToMainFolder() {
    find . -mindepth 2 -type f -print -exec mv {} . \;
    (( $? > 0 )) && printMessages "Operations Fail" 4 ${FUNCNAME[0]} || printMessages "Done" 1
}