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

err() {
    echo "$@" 1>&2
}

find_viewer() {
    if hash feh 2>/dev/null; then
        VIEWER_EXEC='feh -'
    elif hash display 2>/dev/null; then
        VIEWER_EXEC='display -'
    else
        err "Fatal: Could not find any image viewer"
        err "Please install one and set VIEWER_EXEC in the config file."
        exit 1
    fi
}

usage() {
cat << EOF
Usage: ${PROGRAM} [options] pass-name

Options (defaults):

  -c, --config FILE
    Add FILE to the list of config files to read. Can be specified multiple
    times, later files override earlier ones.

  -h, --help
    Show this message and exit.

  -m, --multiline
    Encode all output from pass, not just the first line.

  -s, --dotsize PIXELS (${DOTSIZE})
    Pass-through option to qrencode (there it is -s, --size).

  -t, --timeout SECONDS (${TIMEOUT})
    Wait SECONDS seconds before closing the image viewer. Overrides any settings
    in config files.

  --version
    Output version information and exit.

  -w, --viewer 'COMMAND' ('feh -' or 'display -')
    Pipe QR code image into COMMAND for display. COMMAND is expected to read the
    image from stdin. If you want to print the image to stdout, use -w cat.
    Note that ${PROGRAM} makes no guarantee to not print anything else on
    stdout.

    If no config file specifies a viewer command and this option is not given,
    ${PROGRAM} will look for 'feh' and 'display'. If none is found, the program
    shows an error message and exits with nonzero exit code.

EOF
}

version() {
cat << EOF
Password Store QR add-on, version ${VERSION}
by Emil Lundberg <lundberg.emil@gmail.com>
EOF
}

ARGS="$($GETOPT -o c:s:hmt:w: -l config:,dotsize:,help,multiline,timeout:,version,viewer: -n "$PROGRAM" -- "$@")"
if [[ $? -ne 0 ]]; then
    usage
    exit 1
fi

eval set -- "$ARGS"
while true; do
    case $1 in
        -c|--config)
            shift
            CONFIG+=("$1")
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --version)
            version
            exit 0
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

for config_file in "${CONFIG[@]}"; do
    if [[ -f "$config_file" ]]; then
        eval $(egrep "$CONFIG_PATTERN" "$config_file")
    fi
done

# Parse arguments again, to allow for overriding config settings
eval set -- "$ARGS"
while true; do
    case $1 in
        -s|--dotsize)
            shift
            DOTSIZE=$1
            ;;
        -m|--multiline)
            MULTILINE=true
            ;;
        -t|--timeout)
            shift
            TIMEOUT=$1
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

if [[ -z "$VIEWER_EXEC" ]]; then
    find_viewer
fi

if output=$(pass show "$@"); then
    if ! $MULTILINE; then
        output=$(echo "$output" | head -n1)
    fi

    qrencode -s $DOTSIZE -t PNG -o - "$output" | $VIEWER_EXEC &
    sleep $TIMEOUT
    kill $! 2>/dev/null
fi
