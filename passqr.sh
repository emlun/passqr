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
VERSION=1.1.0
CONFIG=(
    "/etc/${PROGRAM}.conf"
    "${HOME}/.config/${PROGRAM}.conf"
)

# Default settings, can be overriden by config files and options
DOTSIZE=6
MULTILINE=false
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

  -m, --multiline
    Encode all output from pass, not just the first line.

  -s, --dotsize PIXELS (${DOTSIZE})
    Pass-through option to qrencode (there it is -s, --size).

  -t, --timeout SECONDS (${TIMEOUT})
    Wait SECONDS seconds before closing the image viewer.

  --version
    Output version information and exit.

  -w, --viewer 'COMMAND' ('feh -' or 'display -')
    Pipe QR code image into COMMAND for display. COMMAND is expected to read the
    image from stdin. If you want to print the image to stdout, use -w cat.
    Note that ${PROGRAM} makes no guarantee to not print anything else on
    stdout.

EOF
}

version() {
cat << EOF
Password Store QR add-on, version ${VERSION}
by Emil Lundberg <lundberg.emil@gmail.com>
EOF
}

ARGS="$($GETOPT -o s:hmt:w: -l dotsize:,help,multiline,timeout:,version,viewer: -n "$PROGRAM" -- "$@")"
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
        -m|--multiline)
            MULTILINE=true
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
    # Must have a pass-name to pass to pass
    err "Fatal: no pass-name given"
    usage
    exit 1
fi

if [[ -z "$VIEWER_EXEC" ]]; then
    err "No image viewer set. Please set VIEWER_EXEC in a config file or use"
    err "the -w, --viewer 'COMMAND' option. See ${PROGRAM} --help for details."
    exit 1
fi

if output=$(pass show "$@"); then
    if ! $MULTILINE; then
        output=$(echo "$output" | head -n1)
    fi

    qrencode -s $DOTSIZE -t PNG -o - "$output" | $VIEWER_EXEC &
    sleep $TIMEOUT
    kill $! 2>/dev/null
fi
