# Bash-full graphics


https://github.com/user-attachments/assets/1d763a7f-5794-4d7a-a8d7-4b069376cebc



Toy text mode graphic library written in pure bash.

## Why?
Good question.

## What?
* Resolution of 1x2 pixels per 1 character.
* Using terminal alternative screen buffer.
* 100% Code from human. Certifiably awful and non-best-practice-conforming.

## How?
> Note: Check that your terminal is modern enough with support for ANSI escape sequences and Unicode Characters

```bash
#/!bin/bash

source ./path/to/graphic.bash

init_canvas 32 24

# red (9) pixel @ (16,12)
draw_pixel 16 12 9

text "Have a text label."

wait_then_exit_canvas
```

or see [`test.bash`](./test.bash)

## Inspirations:
* [`pxltrm`](<https://github.com/dylanaraps/pxltrm>)

## TODO
* [ ] organizations
* [x] optimization
* [ ] `trap` Ctrl+C
