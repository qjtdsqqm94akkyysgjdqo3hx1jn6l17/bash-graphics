#!/bin/bash

# Toy graphics library written 100% in bash, but with half the resolution of the other one
# Copyright (C) 2025  qjtdsqqm94akkyysgjdqo3hx1jn6l17

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


# from  pxltrm
get_term_size() {
    shopt -s checkwinsize; (:;:)
    [[ -z "${LINES:+$COLUMNS}" ]] && read -r LINES COLUMNS < <(stty size)
}

error(){
    echo "$@" >&2
    wait_then_exit_canvas
    exit 1
}

# coordinate_invalid <x> <y>
coordinate_invalid(){
    if ((1<=$1 && $1<=CANVAS_WIDTH && 1<=$2 && $2<=CANVAS_HEIGHT))
    then
        return 1
    else
        return 0
    fi
}

# init_canvas <width> <height> [<color_index>]
init_canvas(){
    # process stuff
    declare -rg CANVAS_WIDTH="$1" CANVAS_HEIGHT="$2" # DRAW_CHAR=' '
    color="${3:-0}"

    get_term_size()
    if [ "$CANVAS_WIDTH" -gt "$COLUMNS" ] \
        || [ "$CANVAS_HEIGHT" -gt "$LINES" ]
    then
        error "Canvas size ${CANVAS_WIDTH}px x${CANVAS_HEIGHT}px"\
            " can't fit in terminal of size ${LINES}x${COLUMNS}"
    fi

    # enter alternative screen buffer, move cursor to 0,0 and hide it
    # tput smcup
    printf '\033[?1049h\033[;H\033[?25l'

    # technically not needed to be DRAW_CHAR
    local line_con="$(printf " %.0s" $(seq 1 "$CANVAS_WIDTH"))"
    local canvas_lines="$(seq 1 "$CANVAS_HEIGHT")"
    for l in $canvas_lines; do
        printf '\033[48:5:%bm%s\033[0m\n' "$color" "$line_con"
    done
}

# draw_pixel <x> <y> <color_index>
# potential overhead from all the ifs??
draw_pixel(){
    local x="${1:?}"
    local y="${2:?}"
    local color_index="${3:?}"

    if coordinate_invalid "$x" "$y"
    then
        error "Pixel out of bound"
    fi

    printf '\033[%b;%bH\033[48:5:%bm \033[0m' \
        "$y" "$x" \
        "${color_index}"
}

wait_then_exit_canvas(){
    printf '\033[%b;0H\033[0J' "$((CANVAS_HEIGHT + 1))"
    echo "canvas will close once you press [Enter]" >&2
    read
    close_canvas
}

close_canvas(){
    # tput rmcup
    unset CANVAS_WIDTH CANVAS_HEIGHT
    printf '\033[?1049l\033[?25h'
}

text(){

    printf '\e[%b;0H\033[0J%s' "$((CANVAS_HEIGHT + 1))" "$@"
}
