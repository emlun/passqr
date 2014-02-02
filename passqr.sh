#!/bin/bash
#
# Copyright 2014 Emil Lundberg <lundberg.emil@gmail.com>. All rights reserved.
#
# This file is part of passqr.
#
# passqr is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.
#
# passqr is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# passqr. If not, see <http://www.gnu.org/licenses/>.

GETOPT=getopt
PROGRAM="$(basename "$0")"
VERSION=1.3.1
CONFIG=(
    "/etc/${PROGRAM}.conf"
    "${HOME}/.config/${PROGRAM}.conf"
)

# Default settings, can be overriden by config files and options
DOTSIZE=6
LINES=1
TIMEOUT=3
VERBOSE=false
VIEWER_EXEC=''

# Only evaluate config lines matching this pattern
CONFIG_PATTERN='^(DOTSIZE|TIMEOUT|VIEWER_EXEC)='

for config_file in "${CONFIG[@]}"; do
    if [[ -f "$config_file" ]]; then
        eval $(egrep "$CONFIG_PATTERN" "$config_file")
    fi
done

err() {
    echo "$@" 1>&2
}

usage() {
cat << EOF
Usage: ${PROGRAM} [options] pass-name

Options (defaults):

  -h, --help
    Show this message and exit.

  -l, --lines INTEGER or 'all' (1)
    How many lines of output from pass to encode. If this option is not given,
    it is assumed to be 1. If the argument is 'all', encode all output.

  -m, --multiline
    Shorthand for --lines all.

  -s, --dotsize PIXELS (6)
    Pass-through option to qrencode (there it is -s, --size).

  -t, --timeout SECONDS (3)
    Wait SECONDS seconds before closing the image viewer.

  --version
    Show version information and exit.

  -w, --viewer 'COMMAND' (none)
    Use COMMAND to display the QR code image. COMMAND will be appended with a
    single filename. If you want to print the image to stdout, use -w cat, but
    note that ${PROGRAM} makes no guarantee to not print anything else on
    stdout.

Configuration:

  ${CONFIG[*]}

  The config files are evaluated as shell scripts, but only those rows that
  begin with 'SETTING=' where SETTING is one of the following settings:

  DOTSIZE
    Corresponds to the -d, --size option.

  TIMEOUT
    Corresponds to the -t, --timeout option.

  VIEWER_EXEC
    Corresponds to the -w, --viewer option.

  Of course, the chosen format makes the the config files attack vectors since
  they could easily execute arbitrary code. Don't put stupid stuff in them, or
  let anyone else do so.

EOF
}

version() {
cat << EOF
Password Store QR add-on, version ${VERSION}
by Emil Lundberg <lundberg.emil@gmail.com>
EOF
}

ARGS="$($GETOPT -o s:hl:mt:w: -l dotsize:,help,lines:,multiline,timeout:,version,viewer: -n "$PROGRAM" -- "$@")"
if [[ $? -ne 0 ]]; then
    usage
    exit 1
fi
eval set -- "$ARGS"

while true; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -l|--lines)
            shift
            LINES=$1
            ;;
        -m|--multiline)
            LINES=all
            ;;
        -s|--dotsize)
            shift
            DOTSIZE=$1
            ;;
        -t|--timeout)
            shift
            TIMEOUT=$1
            ;;
        --version)
            version
            exit 0
            ;;
        -w|--viewer)
            shift
            VIEWER_EXEC="$1"
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

if [[ $# -eq 0 ]]; then
    # User must pass a pass-name to pass to pass
    err "Fatal: no pass-name given"
    usage
    exit 1
fi

if [[ -z "$VIEWER_EXEC" ]]; then
    err "No image viewer set. Please set VIEWER_EXEC in a config file or use the -w, --viewer 'COMMAND' option. See ${PROGRAM} --help for details."
    err "Recognized config files:"
    for config_file in "${CONFIG[@]}"; do
        err "    $config_file"
    done
    exit 1
fi

output=$(pass show "$@")
passexit=$?
if [[ $passexit -eq 0 ]]; then
    if [[ $LINES != all ]]; then
        output=$(head -n$LINES <<< "$output")
    fi

    tmpfile=$(mktemp --tmpdir "${PROGRAM}.XXXXXXXXXX") || exit $?
    trap "rm '${tmpfile}'" EXIT

    qrencode -s $DOTSIZE -t PNG -o "$tmpfile" "$output" || exit $?
    timeout $TIMEOUT $VIEWER_EXEC "${tmpfile}"

    viewexit=$?
    # Timeout exits with code 124 if command times out
    if [[ $viewexit -eq 124 ]]; then
        exit 0
    else
        exit $viewexit
    fi
else
    err "$output"
    exit $passexit
fi
