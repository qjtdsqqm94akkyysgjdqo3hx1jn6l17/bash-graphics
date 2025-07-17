#!/bin/bash

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

coordinate_valid(){
    if [ "$x" -gt ${CANVAS_WIDTH:?} ] ||\
        [ "$y" -gt ${CANVAS_HEIGHT:?} ] ||\
        [ "$x" -lt 1 ] ||\
        [ "$y" -lt 1 ]
    then
        return 1
    else
        return 0
    fi
}

xy_to_index(){
    local x="${1:?}"
    local y="${2:?}"
    echo $((CANVAS_WIDTH*(y-1)+(x-1)))
}

# init_canvas <width> <height> [<color_index>]
init_canvas(){
    # process stuff
    declare -rg CANVAS_WIDTH="$1" CANVAS_HEIGHT="$2" DRAW_CHAR='▀'
    color="${3:-0}"
    local _canvas_size="$( seq 1 "$((CANVAS_WIDTH*CANVAS_HEIGHT))" )"
    declare -ga CANVAS_BUFFER=( $(printf "$color %.0s" $_canvas_size) )
    # declare -p CANVAS_BUFFER
    # sleep 10
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
        printf '\033[38:5:%bm\033[48:5:%bm%s\033[0m\n' "$color" "$color" "$line_con"
    done
}

# draw_pixel <x> <y> <color_index>
# potential overhead from all the ifs??
draw_pixel(){
    local x="${1:?}"
    local y="${2:?}"
    local color_index="${3:?}"

    if ! coordinate_valid "$x" "$y"
    then
        error "Pixel out of bound"
    fi

    local pixel_index="$(xy_to_index "$x" "$y")"
    CANVAS_BUFFER[$pixel_index]="$color_index"

    # we kinda need to shift y by 1, since
    # y=1 => line number 1/2 = 0 (no! should be 1)
    # y=2 => line number 2/2 = 1 (yes)
    # y=3 => line number 3/2 = 1 (no! should be 2)

    local line_index="$(((y+1)/2))"
    local col_index="$x" # (just for consistency's sake)

    local pixel_odd_index=0 pixel_even_index=0

    # printf '\e[%b;0H\033[0J' "$((CANVAS_HEIGHT/2 + 2))"
    # (exit $((y%2))) is the poor man's `is_even "$y"`
    if (exit $((y%2))); then
        pixel_even_index="$pixel_index"
        pixel_odd_index="$((pixel_index - CANVAS_WIDTH))"
        # echo "EVEN!! ($y)" >&2
    else
        pixel_even_index="$((pixel_index + CANVAS_WIDTH))"
        pixel_odd_index="$pixel_index"
        # echo "ODD!! ($y)" >&2
    fi

    # we gotta update 2 pixel at once...

    # declare -p CANVAS_BUFFER
    # echo "odd=$pixel_odd_index" "even=$pixel_even_index" "index=$pixel_index"
    # echo "row=$line_index" "col=$col_index"
    printf '\033[%b;%bH\033[38:5:%bm\033[48:5:%bm%s\033[0m' \
        "$line_index" "$col_index" \
        "${CANVAS_BUFFER[$pixel_odd_index]}" \
        "${CANVAS_BUFFER[$pixel_even_index]}" \
        "${DRAW_CHAR:?}"
}

# init_canvas_row_col <row> <col> [<color>]
# init_canvas_row_col(){
#     # process stuff
#     declare -rg CANVAS_ROW="$1", CANVAS_COL="$2"
#     get_term_size()
#     if [ "$CANVAS_WIDTH" -gt "$COLUMNS" ] || [ "$CANVAS_HEIGHT" -gt "$LINES" ]
#     # tput smcup
#     printf '\033[?1049h'
# }

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

    printf '\e[%b;0H\033[0J%s' "$((CANVAS_HEIGHT/2 + 2))" "$@"
}
