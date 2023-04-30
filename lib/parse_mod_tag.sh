#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function parse_mod_tag () {
  M[artifact]="j${M[java]}-editsign-v${M[modver]}-mc${M[mcr]}$ARTI.jar"
  local LOADER=
  case "${M[tag]}" in
    EditSign-[A-Z]*-[0-9]* )
      LOADER="${M[tag],,}"
      LOADER="${LOADER#*-}"
      LOADER="${LOADER%%-*}"
      M[artifact]+="-$LOADER"
      ;;
  esac
  M[loader]="$LOADER"
}




return 0
