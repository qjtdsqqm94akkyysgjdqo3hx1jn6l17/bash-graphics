#/!bin/bash

source ./graphic.bash


init_canvas 22 12 15

sleep 1
text "It's morbin time."
sleep 2
for i in {0..255}; do
    # text "x=$(((i+7)%16 + 1)); y=$(((3+i)%16+1))"
    # draw_pixel $(((i+7)%16 + 1)) $(((3+i)%16+1)) $i
    text "x=$((((i+8)/12)%21+1)); y=$(((i+8)%12+1))"
    draw_pixel $((((i+8)/12)%22+1)) $(((i+8)%12+1)) $i
    # clear
    # text "x=$(((i)/21 + 1)); y=$(((i)%12+1))"
    # draw_pixel $((((i)/12)%21+1)) $(((i)%12+1)) $i
    sleep 0.051
done


wait_then_exit_canvas
