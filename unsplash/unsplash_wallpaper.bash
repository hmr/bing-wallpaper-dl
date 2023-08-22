#!/usr/bin/env bash

# vim: set noet syn=bash ft=sh ff=unix fenc=utf-8 ts=2 sw=0 : # GPP default modeline for shell script
# shellcheck shell=bash disable=SC1091,SC3010,SC3021,SC3037 source=${GPP_HOME}
# shellcheck shell=bash disable=SC2155

# Dry run
# DRY_RUN=0

# Debug level (0=DL info only, 1=normal, 2=verbose, 3=more verbose, 6=show json parse result)
DBG_LV=1

# Number of photos to download
MAX=730

# Quality of photo (60 is well-concidered value for the file size and image quality)
QUALITY=60

# Download directory
OUTPUT_DIR="./output"

##### Below are for internal use
PAGE_IDX=0	# Starts from 0
IDX=1				# Starts from 1
API_BASE="https://unsplash.com/napi/search/photos?query=wallpaper&order_by=latest&per_page=30&page=_PAGE_&orientation=landscape&xp="

# Read from STDIN and check it
function read_and_check() {
	read -r LINE || return 1
	[[ ${DBG_LV} -ge 6 ]] && echo "[R]${LINE}"
	if [[ -z ${LINE} ]]; then
		read_and_check
	fi
}

echo "Wallpaper downloader for Unsplash by hmr"
echo

if [[ ! ${DRY_RUN} -gt 0 && ! -d ${OUTPUT_DIR} ]]; then
	echo "Making download directory."
	echo
	mkdir "${OUTPUT_DIR}"
fi

while true
do
	# Making API URL
	PAGE_IDX=$((PAGE_IDX + 1))
	API=${API_BASE//_PAGE_/${PAGE_IDX}}
	[[ ${DBG_LV} -ge 1 ]] && (
		echo "PAGE_IDX: ${PAGE_IDX}";
		echo "MAX: ${MAX}";
		echo "API URL: ${API}";
		echo
	)
	RES=$(curl --silent "${API}")

	while read_and_check
	do

		[[ ${DBG_LV} -ge 1 ]] && echo "#${IDX}"

		# Skip until next border marker
		if ! [[ ${LINE} =~ ^----- ]]; then
			echo "Not align marker. Skip";
			echo
			continue
		fi

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
		if [[ ! ${URL} =~ ^https://images.unsplash.com/ ]]; then
			echo "[Error] Misalignment or a non-free picture detected"
			ggrep -Po "http.://.+?/" <<< "${URL}"
			echo
			continue
		fi

		CREATED_AT_LOC=$(gdate -d "${CREATED_AT_ORIG}" +"%y%m%d%H%M.%S")
		URL=${URL//q=85/q=${QUALITY}}

		if [[ ${DESC} = null && ${ALT_DESC} != null ]]; then
			DESC=${ALT_DESC}
		elif [[ ${DESC} = null && ${ALT_DESC} = null ]]; then
			DESC="no_desc"
		fi
		DESC="$(echo "${DESC}" | cut -c1-60 | tr -d "\"\':;<>/?*|“”‘’")"
		FILENAME="${DESC}-${WIDTH}x${HEIGHT}-q${QUALITY}-${ID}.jpg"

		[[ ${DBG_LV} -ge 3 ]] && echo "created_at(orig): $CREATED_AT_ORIG"
		[[ ${DBG_LV} -ge 3 ]] && echo "touch_date(JST): $CREATED_AT_LOC"
		[[ ${DBG_LV} -ge 3 ]] && echo "id: $ID"
		[[ ${DBG_LV} -ge 2 ]] && echo "desc: $DESC"
		[[ ${DBG_LV} -ge 1 ]] && echo "filename: $FILENAME"
		[[ ${DBG_LV} -ge 3 ]] && echo "url: $URL"

		# Download the photo
		if [[ ${DRY_RUN} -ne 1 ]]; then
			[[ -d ${OUTPUT_DIR} ]] || mkdir ${OUTPUT_DIR}
			if [ -e "${OUTPUT_DIR}/${FILENAME}" ]; then
				echo "File exists. skip."
			else
				#echo -n " downloading..."
				wget --quiet --show-progress -nc -O "${OUTPUT_DIR}/${FILENAME}" "${URL}" \
					&& touch -t "${CREATED_AT_LOC}" -m -c "${OUTPUT_DIR}/${FILENAME}" \
					|| echo "Download error"
			fi
		else
			echo "[DRY RUN] wget --quiet --show-progress -nc -O \"${OUTPUT_DIR}/${FILENAME}\" \"${URL}\" && touch -t \"${CREATED_AT_LOC}\" -m -c \"${OUTPUT_DIR}/${FILENAME}\""
		fi
		[[ ${DBG_LV} -ge 1 || ${DRY_RUN} -ne 0 ]] && echo

		# Exit from the loop when index number reaches max.
		IDX=$((IDX + 1))
		[[ ${IDX} -ge ${MAX} ]] && break 2

	# To exclude promotional photos add 'select (.sponsorship==null)' to jq's filter
	done < <(echo "${RES}" | jq -r '.results[] | "-----", .id, .created_at, .width, .height, .description, .alt_description, .urls.full, .user.username')
done

