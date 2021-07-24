#!/bin/bash

# Debug level
DBG_LV=1

# Download number of photos.
MAX=365

# Quality of photo
QUALITY=60

# Dwonload directory
OUTPUT_DIR="./output"

# Internal use
P_IDX=0
IDX=0
API_BASE="https://unsplash.com/napi/search/photos?query=wallpaper&order_by=latest&per_page=30&page=_PAGE_&orientation=landscape&xp="

while true
do
    # Making API URL
    P_IDX=$((P_IDX + 1))
    API=${API_BASE//_PAGE_/${P_IDX}}
    [ "${DBG_LV}" -ge 3 ] && (
        echo "P_IDX: ${P_IDX}";
        echo "API URL: ${API}" )
    RES=$(curl --silent "${API}")

    while read -r LINE
    do
        IDX=$((IDX + 1))

        read -r LINE && ID=${LINE}
        read -r LINE && CREATED_AT_ORIG=${LINE}
        read -r LINE && WIDTH=${LINE}
        read -r LINE && HEIGHT=${LINE}
        read -r LINE && DESC=${LINE// /_}
        read -r LINE && URL=${LINE}

        CREATED_AT_LOC=$(date -d "${CREATED_AT_ORIG}" +"%y%m%d%H%M.%S")
        URL=${URL//q=85/q=${QUALITY}}
        FILENAME="${DESC}-${WIDTH}x${HEIGHT}-q${QUALITY}-${ID}.jpg"

        [ "${DBG_LV}" -ge 1 ] && echo "#${IDX}"
        [ "${DBG_LV}" -ge 3 ] && echo "created_at(orig): $CREATED_AT_ORIG"
        [ "${DBG_LV}" -ge 3 ] && echo "touch_date(JST): $CREATED_AT_LOC"
        [ "${DBG_LV}" -ge 3 ] && echo "id: $ID"
        [ "${DBG_LV}" -ge 3 ] && echo "desc: $DESC"
        [ "${DBG_LV}" -ge 1 ] && echo "photo: $FILENAME"
        [ "${DBG_LV}" -ge 3 ] && echo "url: $URL"

        # Download the photo
        [ -d ${OUTPUT_DIR} ] || mkdir ${OUTPUT_DIR}
        if [ -e "${OUTPUT_DIR}/${FILENAME}" ]; then
            echo "file exists. skip."
        else
            echo -n "  downloading..."
            wget -q -nc -O "${OUTPUT_DIR}/${FILENAME}" "${URL}" \
                && touch -t "${CREATED_AT_LOC}" -m -c "${OUTPUT_DIR}/${FILENAME}" \
                && echo "done." \
                || echo "ERROR!"
        fi
        [ "${DBG_LV}" -ge 1 ] && echo

        # Exit from the loop when index number reaches max.
        [ "${IDX}" -ge "${MAX}" ] && break 2

    # To exclude promotional photos add 'select (.sponsorship==null)'
    done < <(echo "${RES}" | jq -r '.results[] | "-----", .id, .created_at, .width, .height, .alt_description, .urls.full')
done

