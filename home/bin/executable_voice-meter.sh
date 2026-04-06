#!/bin/bash

tput civis
trap 'tput cnorm; exit 0' INT TERM

HEIGHT=6
BARS=14
CHUNK=1600
SCALE=500

history=()
for ((i=0; i<BARS; i++)); do
    history+=(0)
done

render() {
    awk -v hist="$*" -v H=$HEIGHT -v B=$BARS '
    BEGIN {
        split(hist, h, " ")
        T = H * 8
        g="\033[92m"; y="\033[93m"; r="\033[91m"; R="\033[0m"
        b[1]="▁"; b[2]="▂"; b[3]="▃"; b[4]="▄"; b[5]="▅"; b[6]="▆"; b[7]="▇"

        for (row=0; row<H; row++) {
            rb = H-1-row
            line = ""
            for (col=1; col<=B; col++) {
                f = int((h[col]+0)*T/100)
                full = int(f/8)
                part = f%8
                c = (rb < H*0.6) ? g : (rb < H*0.8) ? y : r
                if (rb < full)                   line = line c "█" R
                else if (rb == full && part > 0)  line = line c b[part] R
                else                             line = line " "
            }
            print line
        }
        pad = ""
        for (i=0; i<int((B-5)/2); i++) pad = pad " "
        printf pad r "●" R " REC"
    }'
}

parec --rate=16000 --channels=1 --format=s16le --latency-msec=50 2>/dev/null | \
while true; do
    peak=$(head -c $CHUNK | \
        sox -t raw -r 16000 -c 1 -b 16 -e signed - -n stat 2>&1 | \
        awk -v s=$SCALE '/Maximum amplitude/ {v=int($3 * s); if(v>100) v=100; print v}')

    peak=${peak:-0}
    history=("${history[@]:1}" "$peak")

    printf "\e[H"
    render "${history[@]}"
done
