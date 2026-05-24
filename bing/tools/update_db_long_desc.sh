#!/usr/bin/env bash
#
# vim: set noet syn=bash ft=sh ff=unix fenc=utf-8 ts=4 sw=0 : # GPP default modeline for shell script
# shellcheck shell=bash disable=SC1091,SC2207,SC2155,SC3010,SC3021,SC3037
#
# bing-wallpaper-dl.bash
# Download wallpapers from Bing Wallpaper Gallery(https://peapix.com)
#
# AUTHOR: hmr
# ORIGIN: 2024-03-25T22:03:23

GNU_GREP_BIN="ggrep"
GNU_SED_BIN="gsed"

DB_FILE="bing_wallpaper.sqlite"
ERROR_LOG_FILE="$0.log"
cp /dev/null "${ERROR_LOG_FILE}"

query="SELECT detail_page FROM bing_photos;"
result=$(sqlite3 "${DB_FILE}" "$query")

for dpage in ${result}; do
	DETAIL_PAGE_URL="https://peapix.com/bing/${dpage}"

	HTML="$(curl -s "${DETAIL_PAGE_URL}")"

	PHOTO_TITLE="$(echo "${HTML}" | grep "og:title" | "${GNU_SED_BIN}" -e 's/.\+content="\(.\+\)".\+$/\1/g')"
	PHOTO_TITLE_SAFE=""
	if [[ ${OPT_SPC_DELETE} ]]; then
		PHOTO_TITLE_SAFE="$(echo "${PHOTO_TITLE}" | tr -d " "  | tr "/" "-")"
	elif [[ ${OPT_SPC_TR_HYPHEN} ]]; then
		PHOTO_TITLE_SAFE="$(echo "${PHOTO_TITLE}" | tr " " "-" | tr "/" "-")"
	elif [[ ${OPT_SPC_TR_UNDER} ]]; then
		PHOTO_TITLE_SAFE="$(echo "${PHOTO_TITLE}" | tr " " "_" | tr "/" "-")"
	else
		PHOTO_TITLE_SAFE="$(echo "${PHOTO_TITLE}" | tr "/" "-")"
	fi
	PHOTO_DATE="$(echo "${HTML}" | grep -o '<time datetime=".*">' | "${GNU_SED_BIN}" -e 's/<time datetime="\([0-9-]\+\)">/\1/g')"

	PHOTO_COPYRIGHT=$(echo "$HTML" | grep '<p class="text-body-secondary fs-sm mb-3">' | sed -e 's/^ *//' -e 's|<[^>]\+>||g' -e 's/[\r\n\x00]*$//')
	PHOTO_COPYRIGHT_SAFE="${PHOTO_COPYRIGHT//\'/\'\'}"

	PHOTO_LONG_DESC=$(echo "$HTML" | ${GNU_GREP_BIN} -Pzo '(?s)<div class=\"position-relative\">\K.*?(?=</div>)' | ${GNU_SED_BIN} -E -e 's/^ +//g' -e '1,2d' -e 's|<[^>]+>||g' -e 's/[\r\n\x00]*$//')
	PHOTO_LONG_DESC_SAFE="${PHOTO_LONG_DESC//\'/\'\'}"

	PHOTO_UPDATED_DATE="$(date +'%Y-%m-%d')"

	echo "------------------------------------------------------------------"
	echo "${dpage}"
	echo "${PHOTO_DATE} / ${PHOTO_TITLE_SAFE}"
	# echo "Copyright: ${PHOTO_COPYRIGHT_SAFE}"
	# echo "Long Desc: ${PHOTO_LONG_DESC_SAFE}"

	query="update bing_photos set updated_date='${PHOTO_UPDATED_DATE}', copyright='${PHOTO_COPYRIGHT_SAFE}', long_desc='${PHOTO_LONG_DESC_SAFE}' where detail_page='${dpage}'"
	echo "${query}"

	sqlite3 "${DB_FILE}" <<< "${query}" 2>> "${ERROR_LOG_FILE}"
	RETCODE=$?
	if [[ ${RETCODE} -ne 0 ]]; then
		echo "ERROR: DB insert error at ${dpage} [code:${RETCODE}] @ ${FUNCNAME[0]}" 2>> "${ERROR_LOG_FILE}"
	fi

	sleep 1
done

