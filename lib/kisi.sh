#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function vdo () {
  echo "=== run: $* ==="
  SECONDS=0
  "$@"
  local RV=$?
  echo "=== done: $*, rv=$RV, took $SECONDS sec ==="
  return $RV
}


function fmt_markdown_details_file () {
  echo "<details><summary>$1</summary>"
  shift
  echo
  echo '```'"$1"
  shift
  sed -re '/^\x60{3}/s~^.~\&#96;~' -- "$@"
  echo '```'
  echo
  echo "</details>"
  echo
}


function ghstep_dump_file () {
  fmt_markdown_details_file "$@" >>"$GITHUB_STEP_SUMMARY" || return $?
}










[ "$1" == --lib ] && return 0; "$@"; exit $?
