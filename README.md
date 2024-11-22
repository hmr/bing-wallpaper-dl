# wallpaper-downloaders
A collection of small scripts to download wallpapers.

## Usage

### Clone
Clone this repository `git clone https://github.com/hmr/bing-wallpaper-dl.git`

### For Bing Wallpaper
- cd to bing directory `cd bing`
- mkdir output directory `mkdir output`
- 1st time execution
    - `./bing-wallpaper-dl_peapix --gallery-all --concurrent-month --ignore-url-check`
- 2nd time execution
    - `./bing-wallpaper-dl_peapix --gallery-all --concurrent-month --auto-resume --ignore-url-check`

### For Unsplash's wallpaper collection
- cd to unsplash directory `cd unsplash`
- mkdir output directory `mkdir output`
- execute `./unsplash-wallpaper.bash`

## Supported platform
Any unix/linux/macOS with following softwares installed.
- bash
- curl
- sips(macOS only) or identify(ImageMagick)
- GNU grep
- GNU sed
- GNU date(coreutils)
- jq (unsplash only)

##  Detailed description

### Bing Wallpaper Downloader

This script downloads Bing Wallpapers from today's date to the past (until 2010-01-01). You can select multiple galleries (countries).

Syntax: `bing-wallpaper-dl_peapix [Options]`

#### Options:
##### --concurrent-gallery
[BETA] Parallel download for galleries.
For example if you assign "--gallery-us" and "--gallery-it", this option will

##### --concurrent-month
[BETA] Parallel download for months.

##### --concurrency
[BETA] Maximum number of concurrent processes [default: 4].

##### --gallery-[COUNTRY]
Bing Wallpaper is available in many countries. This option is for selecting them. For example, to select Japan, use `--gallery-jp`. Multiple countries can be specified. `--gallery-all` is equivalent to specifying all countries.
COUNTRY: all, jp, us, uk, au, ca, in, fr, it, de, es, br, cn
[default: all]

##### --dry-run
Do a Dry-run. This does not make any changes.

##### --force-all
By default, the tool downloads images in date order from newest to oldest, and terminates when it reaches a previously downloaded image. Setting this option will prevent it from stopping in that case. This is useful if you want to download all images across the gallery.

##### --uhd
Download UHD photos only.

##### --hd
Download HD and UHD photos only.

##### --spc-del
Delete spaces in file name when saving.

##### --spc-hyphen
Replace spaces in file names with hyphens when saving.

##### --spc-under
Replace spaces in file names with underscores when saving.

##### --resume-by-db
Resume downloading from the last point stored in the DB.

##### --help
Display this help and exit.
