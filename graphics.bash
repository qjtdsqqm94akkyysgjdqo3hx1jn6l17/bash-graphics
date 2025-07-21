#!/bin/bash

# Toy graphics library written 100% in bash.
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
    # this SEEMED more performant??
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
    declare -rg \
        CANVAS_WIDTH="${1:?Must provide a width}" \
        CANVAS_HEIGHT="${2:?Must provide a height}" \
        DRAW_CHAR='▀' \
        DEFAULT_COLOR="${3:-0}"

    # We'll just use the Buffer to store any color the canvas is updated with
    # and fall back to DEFAULT_COLOR if no color was specified in a given index
    # AKA no need to initialized BUFFER with default values
    declare -ga CANVAS_BUFFER

    get_term_size()

    if [ "$CANVAS_WIDTH" -gt "$COLUMNS" ] \
        || [ "$CANVAS_HEIGHT" -gt "$((LINES*2))" ]
    then
        error "Canvas size ${CANVAS_WIDTH}px x${CANVAS_HEIGHT}px"\
            "(${CANVAS_WIDTH} columns & $(((CANVAS_HEIGHT / 2) + (CANVAS_HEIGHT % 2))) rows)"\
            " can't fit in terminal of size ${LINES}x${COLUMNS}"
    fi

    # enter alternative screen buffer, move cursor to 0,0 and hide it
    # tput smcup
    printf '\033[?1049h\033[;H\033[?25l'

    # technically not needed to be DRAW_CHAR
    line_con="$(printf "${DRAW_CHAR}%.0s" $(seq 1 "$CANVAS_WIDTH"))"
    canvas_lines="$(seq 1 "$(((CANVAS_HEIGHT / 2) + (CANVAS_HEIGHT % 2)))")"
    for l in $canvas_lines; do
        printf '\033[38:5:%bm\033[48:5:%bm%s\033[0m\n' "$DEFAULT_COLOR" "$DEFAULT_COLOR" "$line_con"
    done
}

# draw_pixel <x> <y> <color_index>
draw_pixel(){
    local x="${1:?}"
    local y="${2:?}"
    local color_index="${3:?}"

    if coordinate_invalid "$x" "$y"
    then
        error "Pixel out of bound"
    fi

    # why does doing this inline instead of via xy_to_index() net
    # a 200% in performance???
    local pixel_index="$((y+x*CANVAS_HEIGHT))"
    CANVAS_BUFFER[$pixel_index]="$color_index"

    # we kinda need to shift y by 1, since
    # y=1 => line number 1/2 = 0 (no! should be 1)
    # y=2 => line number 2/2 = 1 (yes)
    # y=3 => line number 3/2 = 1 (no! should be 2)

    # binary operation equiv to (y+1)/2
    local line_index="$(((y+1)>>1))"
    local col_index="$x" # (just for consistency's sake)

    local pixel_odd_index pixel_even_index

    # binary operation equiv. to y%2
    if ((y & 1)); then
        pixel_even_index="$((pixel_index + 1))"
        pixel_odd_index="$pixel_index"
        # text "ODD!! ($y)" >&2
    else
        pixel_even_index="$pixel_index"
        pixel_odd_index="$((pixel_index - 1))"
        # text "EVEN!! ($y)" >&2
    fi

    # we gotta update 2 pixel at once!
    printf '\033[%b;%bH\033[38:5:%bm\033[48:5:%bm%s\033[0m' \
        "$line_index" "$col_index" \
        "${CANVAS_BUFFER[$pixel_odd_index]-${DEFAULT_COLOR}}" \
        "${CANVAS_BUFFER[$pixel_even_index]-${DEFAULT_COLOR}}" \
        "${DRAW_CHAR:?}"
}


wait_then_exit_canvas(){
    printf '\033[%b;0H\033[0J' "$((CANVAS_HEIGHT/2 + 2))"
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

    printf '\e[%b;0H\033[0J%s' "$(((CANVAS_HEIGHT>>1) + 2))" "$@"
}
