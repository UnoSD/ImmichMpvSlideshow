#!/bin/bash

IMMICH_USERNAME=""
IMMICH_URL=""
EXCLUDE_PEOPLE=("Guybrush Threepwood"
                "Largo LaGrande")

mpv --fullscreen \
    --input-ipc-server=/tmp/mpvsocket \
    --image-display-duration=2 \
    --http-header-fields="x-api-key: $(secret-tool lookup username $IMMICH_USERNAME)" \
    --force-window \
    --prefetch-playlist=yes \
    --idle > /dev/null &

while true; do
    RESULT=$(curl -s \
                  -L "$IMMICH_URL/api/search/random" \
                  -H "Content-Type: application/json" \
                  -H "Accept: application/json" \
                  -d '{"size":1,"withPeople":true}' \
                  -H "x-api-key: $(secret-tool lookup username $IMMICH_USERNAME)")
    
    mapfile -t PEOPLE < <(jq '.[].people[].name' -r <<<"$RESULT")

    ID=$(jq '.[].id' -r <<<"$RESULT")
    
    for PERSON in "${PEOPLE[@]}"; do
        if [[ -n $PERSON && ${EXCLUDE_PEOPLE[@]} =~ $PERSON ]]; then
            echo "Contains excluded $PERSON, skipping next"
            continue 2
        fi
    done
    
    sleep 1
    
    echo '{"command": ["loadfile", "'$IMMICH_URL'/api/assets/'$ID'/original#'${PEOPLE[@]}'", "append-play"]}' | \
    socat - /tmp/mpvsocket > /dev/null || exit 0
done
