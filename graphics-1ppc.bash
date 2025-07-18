#!/bin/bash
# DRAW_CHAR is always ` ` here (since some terminals with line height>1 don't compensate for block chars properly)

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

    if ! coordinate_valid "$x" "$y"
    then
        error "Pixel out of bound"
    fi

    printf '\033[%b;%bH\033[48:5:%bm \033[0m' \
        "$y" "$x" \
        "${color_index}"
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
