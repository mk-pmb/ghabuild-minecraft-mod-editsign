#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function naive_json_to_shell_dict () {
  sed -nrf <(echo '
    s~\\|\a~~g
    s~\x27+~\a& ~g
    s~^ *("[^"]+"): *("[^"]*"|[0-9a-z.-]+),?$~[\n\1]=\n\2~
    /\n/{
      s~\n"([A-Za-z0-9_:./+-]+)"~\1~g
      s~\n"([^"]*)"~\x27\1\x27~g
      s~\a(\S+) ~\x27"\1"\x27~g
      s~\n([0-9])~\1~g
      p
    }
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
    case "$K" in
      *=* ) V="${K#*=}"; K="${K%%=*}";;
      * ) eval 'V="${'"$D"'["$K"]}"';;
    esac
    case "$V" in
      '' | *[^0-9]* ) V='"'"$V"'"';;
    esac
    printf -v V ' "%s": %s,' "$K" "$V"
    B+="$V"
  done
  echo -n "${B%,}$A"
}










[ "$1" == --lib ] && return 0; "$@"; exit $?
