#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function build_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?
  source -- lib/json.sh --lib || return $?
  source -- lib/kisi.sh --lib || return $?
  source -- lib/mdtbl_read.sh --lib || return $?

  local UNJAR='jar-unpacked'
  local AUX_META_DIR="$UNJAR/META-INF"
  mkdir --parents -- "$AUX_META_DIR" || return $?

  [ -n "$GITHUB_OUTPUT" ] || local GITHUB_OUTPUT='tmp.github_output.env'
  [ -n "$GITHUB_STEP_SUMMARY" ] \
    || local GITHUB_STEP_SUMMARY='tmp.github_stepsum.md'

  build_"$@"
  local RV=$?
  status_report_tall_gapped_on_ci "$RV"
  return "$RV"
}


function build_sh () { "$@"; }


function build_inverse_rebase () {
  local BRAN="${1:-$INVERSE_REBASE_ONTO}"
  if [ -z "$BRAN" ]; then
    echo "D: $FUNCNAME: Branch not set. Skip."
    return 0
  fi
  git fetch --unshallow origin "$BRAN" || return $?
  git branch --force {,origin/}"$BRAN" || return $?
  local SELF="$(basename -- "$BASH_SOURCE")"
  git checkout -b rebased || return $?
  git checkout "$BRAN" -- "$SELF" lib/ || return $?
  ./"$SELF" "${FUNCNAME#*_}_stage2" "$@" || return $?
}


function build_inverse_rebase_stage2 () {
  local BRAN="${1:-$INVERSE_REBASE_ONTO}"
  echo "--- Inverse rebase stage 2 -> '$BRAN' ---"
  vdo git branch --verbose || return $?
  local ORIG="$(git rev-parse HEAD)"
  vdo git log --oneline "$BRAN" || return $?
  vdo git log --oneline "$ORIG" || return $?

  local TREE='git log --oneline --graph --decorate --all'
  vdo $TREE || return $?
  vdo git reset --hard "$BRAN" || return $?

  # Identity is required before we can rebase:
  git config --global user.name   'CI'
  git config --global user.email  'ci@example.net'
  vdo git rebase -- "${ORIG:0:7}" || return $?

  vdo $TREE || return $?
}


function build_find_mod_repo_url () {
  <"$SELFPATH"/README.md sed -nrf <(echo '
    s~^\* __Mod repo:__( |$)~~;T
    /\S/!N
    s~^\s+~~
    s~\s+$~~
    p
    ')
}


function build_clone_mod_repo () {
  local BARE=
  if [ "$1" == --bare ]; then BARE="$1"; shift; fi
  vdo git init mod-repo $BARE || return $?

  cd -- mod-repo || return $?
  local URL="$(build_find_mod_repo_url)"
  [ -n "$URL" ] || return 4$(echo 'E: Unable to detect mod repo URL!' >&2)
  vdo git remote add origin "$URL" || return $?
  local F_OPT=(
    --tags
    --depth=1
    --no-recurse-submodules
    )
  vdo git fetch "${F_OPT[@]}" origin || return $?

  # Unfortunately, EditSign has no master or main branch, so we
  # have to maintain our own default:
  [ -n "$MOD_REF" ] || local MOD_REF='refs/remotes/origin/minecraft/1.19.4'
  vdo git branch --force mod-ref "$MOD_REF" || return $?

  if [ -z "$BARE" ]; then
    vdo git checkout --force mod-ref || return $?
    vdo git reset --hard HEAD || return $?
  fi
}


function build_generate_matrix () {
  sed -nre 's~^(\s*)([a-z][^: ]*):~  \1"\2":~p' -- ci.cfg | sed -rf <(echo '
    $!s~$~,~
    1s~^ ~opt={~
    $s~$~\n}~
    ') >>"$GITHUB_OUTPUT" || return $?

  local M=
  for M in matrix.override.{json,md} matrix.md ''; do
    [ -f "$M" ] && break
  done
  echo "D: Reading build matrix from: $M"
  case "$M" in
    *.json ) M="$(LANG=C sed -re '1s~^\xEF\xBB\xBF~~' -- "$M")";;
    *.md ) M="$(<"$M" mdtbl_for_each_row build_fmt_matrix_line)";;
  esac
  [ -n "$M" ] || M='[ { "": "placeholder" } ]'
  <<<"$M" vdo tee -- 'tmp.matrix.json' || return $?
  <<<'mx={ "b": '"${M//$'\n'/ }"' }' vdo tee --append \
    -- "$GITHUB_OUTPUT" || return $?
}


function build_fmt_matrix_line () {
  local -A M=()
  eval "M=( $1 )"
  [ "${M[#]}" == 1 ] && echo '['

  local TAG="${M[tag]}"
  local ARTI=
  case "$TAG" in
    EditSign-[A-Z]*-[0-9]* )
      ARTI="${M[tag],,}"
      ARTI="${ARTI#*-}"
      ARTI="-${ARTI%%-*}"
      ;;
  esac
  local ARTI="editsign-v${M[modver]}-mc${M[mcr]}$ARTI.jar"

  naive_jsonify_oneline M '{' ' }' \
    modver mcr license java tag \
    artifact="$ARTI" \
    modref="refs/tags/$TAG" \
    || return $?
  if [ "${M[#]}" == "${M[##]}" ]; then
    echo
    echo ']'
  else
    echo ','
  fi
}


function build_summarize_step_env_vars () {
  local TITLE= TEXT= FMT=
  for TEXT in "$@"; do
    eval 'TEXT="$'"$TEXT"'"'
    [ -n "$TEXT" ] || continue
    TITLE="${TEXT%% <*}"; TEXT="${TEXT#* <}"
    FMT="${TEXT%%> *}"; TEXT="${TEXT#*> }"
    ghstep_dump_file "$TITLE" "${FMT:-text}" <<<"$TEXT" || return $?
  done
}


function build_shellify_build_matrix_entry () {
  echo "$JSON" >tmp.matrix_entry.json
  <<<"$JSON" naive_json_to_shell_dict | tee -- tmp.matrix_entry.dict \
    | ghstep_dump_file "Build matrix entry as bash dict" bash || return $?
}


function build_apply_hotfixes () {
  echo 'Stub!'
}


function build_gradle () {
  # local -A MX=(); read_build_matrix_entry || return $?
  cd -- mod-repo || return $?

  local GHL="../$AUX_META_DIR"/git_head.txt
  [ -f "$GHL" ] || git log -n 1 >"$GHL" || return $?

  chmod a+x gradlew || return $?
  local GW_OPT=(
    --stacktrace
    --info
    --scan
    )
  vdo ./gradlew clean "${GW_OPT[@]}" || true
  local GR_LOG='../tmp.gradlew.log'
  VDO_TEE="$GR_LOG" vdo ./gradlew build "${GW_OPT[@]}" && return 0
  local GR_RV=$?

  local GR_HL='../tmp.gradlew.hl.log'
  "$SELFPATH"/lib/gradle_log_highlights.sed "$GR_LOG" | tee -- "$GR_HL"
  fmt_markdown_details_file "Gradle failed, rv=$GR_RV" text "$GR_HL" \
    >>"$GITHUB_STEP_SUMMARY"

  return "$GR_RV"
}


function build_grab () {
  cp --no-clobber --no-target-directory \
    -- {tmp.,"$AUX_META_DIR"/build_}matrix_entry.json || return $?

  local OUT='mod-repo/build/libs'
  vdo delete_confusing_jars || return $?

  echo "=== Detecting JAR files… ==="
  local JAR="$(cd -- "$OUT" && find -type f -name '*.jar' -printf '%f\n')"
  nl -ba <<<"$JAR"
  case "$JAR" in
    '' ) echo "E: Found none!" >&2; return 3;;
    *$'\n'* ) echo 'E: Found too many candidates!' >&2; return 3;;
    EditSign-*.jar ) ;;
    * ) echo "E: Unexpected naming schema!" >&2; return 3;;
  esac

  echo "$JAR" >"$AUX_META_DIR"/orig_build_filename.txt || return $?
  vdo unzip -d "$UNJAR" -- "$OUT/$JAR" || return $?
  vdo ls -l -- "$UNJAR" || return $?
}


function delete_confusing_jars () {
  local LIST=(
    "$OUT"/EditSign-*-{sources,deobf}.jar
    )
  local ITEM=
  for ITEM in "${LIST[@]}"; do
    [ ! -f "$ITEM" ] || rm --verbose -- "$ITEM" || return $?
  done
}









build_init "$@"; exit $?
