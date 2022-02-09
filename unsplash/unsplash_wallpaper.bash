#!/bin/bash

# Dry run
DRY_RUN=0

# Debug level
DBG_LV=10

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

# Read from STDIN and check it
function read_and_check() {
	read -r LINE || return 1
	[[ ${DBG_LV} -ge 6 ]] && echo "[R]${LINE}"
	if [[ -z ${LINE} ]]; then
		read_and_check
	fi
}

while true
do
    # Making API URL
    P_IDX=$((P_IDX + 1))
    API=${API_BASE//_PAGE_/${P_IDX}}
    [[ ${DBG_LV} -ge 3 ]] && (
        echo "P_IDX: ${P_IDX}";
        echo "API URL: ${API}" )
    RES=$(curl --silent "${API}")

    while read_and_check
    do
	# Skip until next border marker
	if ! [[ ${LINE} =~ ^----- ]]; then
		echo "Not align marker. Skip";
		echo
		continue
	fi

        IDX=$((IDX + 1))

        read_and_check && ID=${LINE}
        read_and_check && CREATED_AT_ORIG=${LINE}
        read_and_check && WIDTH=${LINE}
        read_and_check && HEIGHT=${LINE}
        read_and_check && DESC=${LINE// /_}
        read_and_check && ALT_DESC=${LINE// /_}
        read_and_check && URL=${LINE}
	read_and_check && USERNAME=${LINE}
	#read -r LINE && ORIG_DESC=${LINE}

	# Detect misalignment
	if ! [[ ${URL} =~ ^https://images.unsplash.com/ ]]; then
		echo "Detect misalignment!"
		echo
		continue
	fi

        CREATED_AT_LOC=$(date -d "${CREATED_AT_ORIG}" +"%y%m%d%H%M.%S")
        URL=${URL//q=85/q=${QUALITY}}

	if [[ ${DESC} = null && ${ALT_DESC} != null ]]; then
		DESC=${ALT_DESC}
	elif [[ ${DESC} = null && ${ALT_DESC} = null ]]; then
		DESC="no_desc"
	fi
	DESC="$(echo "${DESC}" | cut -c1-60 | tr -d "\"\':;<>/?*|")"
        FILENAME="${DESC}-${WIDTH}x${HEIGHT}-q${QUALITY}-${ID}.jpg"

        [[ ${DBG_LV} -ge 1 ]] && echo "#${IDX}"
        [[ ${DBG_LV} -ge 3 ]] && echo "created_at(orig): $CREATED_AT_ORIG"
        [[ ${DBG_LV} -ge 3 ]] && echo "touch_date(JST): $CREATED_AT_LOC"
        [[ ${DBG_LV} -ge 3 ]] && echo "id: $ID"
        [[ ${DBG_LV} -ge 3 ]] && echo "desc: $DESC"
        [[ ${DBG_LV} -ge 1 ]] && echo "photo: $FILENAME"
        [[ ${DBG_LV} -ge 3 ]] && echo "url: $URL"

        # Download the photo
	if [[ ${DRY_RUN} -ne 1 ]]; then
		[[ -d ${OUTPUT_DIR} ]] || mkdir ${OUTPUT_DIR}
		if [ -e "${OUTPUT_DIR}/${FILENAME}" ]; then
			echo "file exists. skip."
		else
			echo -n "  downloading..."
			wget -q -nc -O "${OUTPUT_DIR}/${FILENAME}" "${URL}" \
				&& touch -t "${CREATED_AT_LOC}" -m -c "${OUTPUT_DIR}/${FILENAME}" \
				&& echo "done." \
				|| echo "ERROR!"
		fi
		[[ ${DBG_LV} -ge 1 ]] && echo
	else
		echo "[DRY RUN] Skip"
		echo
	fi

        # Exit from the loop when index number reaches max.
        [[ ${IDX} -ge ${MAX} ]] && break 2

    # To exclude promotional photos add 'select (.sponsorship==null)'
    done < <(echo "${RES}" | jq -r '.results[] | "-----", .id, .created_at, .width, .height, .description, .alt_description, .urls.full, .user.username')
done

