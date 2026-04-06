#!/bin/bash

tput civis
trap 'tput cnorm; exit 0' INT TERM

STATE_FILE="/tmp/whisper/meter.state"
LANG_FILE="/tmp/whisper/lang"
MODEL_FILE="/tmp/whisper/model"
HEIGHT=6
BARS=14
CHUNK=1600
SCALE=500

history=()
for ((i=0; i<BARS; i++)); do
    history+=(0)
done

get_tag() {
    local lang model m
    lang=$(cat "$LANG_FILE" 2>/dev/null)
    lang=${lang:-en}
    lang=${lang^^}
    model=$(cat "$MODEL_FILE" 2>/dev/null)
    model=${model:-large-v3}
    case "$model" in
        large*) m="L" ;;
        medium) m="M" ;;
        turbo)  m="T" ;;
        *)      m="?" ;;
    esac
    echo "${lang}·${m}"
}

render_waveform() {
    local tag="$1"
    shift
    awk -v hist="$*" -v H=$HEIGHT -v B=$BARS -v tag="$tag" '
    BEGIN {
        split(hist, h, " ")
        T = H * 8
        g="\033[92m"; y="\033[93m"; r="\033[91m"; d="\033[90m"; R="\033[0m"
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
        tl = length(tag)
        pad = ""
        for (i=0; i < B - 4 - tl; i++) pad = pad " "
        printf r "●" R "REC" pad d tag R
    }'
}

render_processing() {
    local pos=$1
    local tag=$2
    local c="\033[96m"
    local dl="\033[36m"
    local dd="\033[90m"
    local R="\033[0m"

    printf "\e[H"
    local mid=$((HEIGHT / 2))
    for ((row=0; row<HEIGHT; row++)); do
        if ((row == mid)); then
            local line=""
            for ((col=0; col<BARS; col++)); do
                local dist=$((col - pos))
                ((dist < 0)) && dist=$((-dist))
                case $dist in
                    0) line+="${c}█${R}" ;;
                    1) line+="${dl}▓${R}" ;;
                    2) line+="${dd}▒${R}" ;;
                    3) line+="${dd}░${R}" ;;
                    *) line+=" " ;;
                esac
            done
            echo -e "$line"
        else
            printf "%${BARS}s\n"
        fi
    done
    local tl=${#tag}
    local pad_len=$((BARS - 4 - tl))
    local pad=""
    for ((i=0; i<pad_len; i++)); do pad+=" "; done
    printf "${c}◎${R}···${pad}${dd}${tag}${R}"
}

render_done() {
    local g="\033[92m"
    local R="\033[0m"

    printf "\e[2J\e[H"
    for ((row=0; row<HEIGHT; row++)); do
        case $row in
            1) printf "       ${g}/${R}      \n" ;;
            2) printf "      ${g}/${R}       \n" ;;
            3) printf " ${g}\\${R}   ${g}/${R}        \n" ;;
            4) printf "  ${g}\\ /${R}         \n" ;;
            5) printf "   ${g}v${R}          \n" ;;
            *) printf "%${BARS}s\n" ;;
        esac
    done
    printf "    ${g}✓${R} OK   "
}

get_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "recording"
}

parec --rate=16000 --channels=1 --format=s16le --latency-msec=50 2>/dev/null | \
while true; do
    [[ "$(get_state)" != "recording" ]] && break
    peak=$(head -c $CHUNK | \
        sox -t raw -r 16000 -c 1 -b 16 -e signed - -n stat 2>&1 | \
        awk -v s=$SCALE '/Maximum amplitude/ {v=int($3 * s); if(v>100) v=100; print v}')

    peak=${peak:-0}
    history=("${history[@]:1}" "$peak")

    printf "\e[H"
    render_waveform "$(get_tag)" "${history[@]}"
done

printf "\e[2J"
pos=0
dir=1
timeout=0
tag=$(get_tag)
while [[ "$(get_state)" == "processing" ]]; do
    render_processing $pos "$tag"
    ((pos += dir))
    ((pos >= BARS - 1)) && dir=-1
    ((pos <= 0)) && dir=1
    ((timeout++))
    ((timeout > 600)) && break
    sleep 0.05
done

if [[ "$(get_state)" == "done" ]]; then
    render_done
    sleep 2
fi

tput cnorm
