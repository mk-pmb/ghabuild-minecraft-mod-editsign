#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function naive_json_to_shell_dict () {
  sed -nrf <(echo '
    s~\x27|\\~~g
    s~^ *"([^"]+)": *("[^"]*"|[0-9]+),?$~[\x27\1\x27]=\x27\2\x27~p
    ') -- "$@"
}


function naive_jsonify_oneline () {
  if [ "$#" -lt 2 ]; then
    echo -n '{}'
    return 0
  fi
  local D="$1"; shift # <d>ictionary
  local B="$1"; shift # print this <b>efore key/value pairs
  local A="$1"; shift # print this <a>fter key/value pairs
  local K= V= # <k>ey/<v>alue pair
  for K in "$@"; do
    V=
    eval 'V="${'"$D"'["$K"]}"'
    case "$V" in
      '' | *[^0-9]* ) V='"'"$V"'"';;
    esac
    printf -v V ' "%s": %s,' "$K" "$V"
    B+="$V"
  done
  echo -n "${B%,}$A"
}










return 0
