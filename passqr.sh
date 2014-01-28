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
VERSION=1.0.0
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
CONFIG_PATTERN='^(DOTSIZE|TIMEOUT|VIEWER_EXEC)'

err() {
    echo "$@" 1>&2
}

trace() {
    if $VERBOSE; then
        echo "$@"
    fi
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

  -v, --verbose
    Output information about what the program is doing. This may include
    sensitive information such as pass-name.

  --version
    Output version information and exit.

  -w, --viewer 'COMMAND' ('feh -' or 'display -')
    Pipe QR code image into COMMAND for display. COMMAND is expected to read the
    image from stdin. If you want to print the QR code to stdout, use -w cat and
    make sure not to use the --verbose option.

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

ARGS="$($GETOPT -o c:s:hmt:vw: -l config:,dotsize:,help,multiline,timeout:,verbose,version,viewer: -n "$PROGRAM" -- "$@")"
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
        trace "Reading config file ${config_file}"
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
        -v|--verbose)
            VERBOSE=true
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

pass_cmd="pass show $@"
if output=$($pass_cmd); then
    if $MULTILINE; then
        trace "Encoding all output of '${pass_cmd}'"
    else
        trace "Encoding first line of output of '${pass_cmd}'"
        output=$(echo "$output" | head -n1)
    fi

    trace "Dot size: ${DOTSIZE} px"

    qrencode -s $DOTSIZE -t PNG -o - "$output" | $VIEWER_EXEC &
    sleep $TIMEOUT
    kill $! 2>/dev/null
fi
