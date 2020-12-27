#!/bin/bash
# Get current Spotify status with play/pause button
#
# by Jason Tokoph (jason@tokoph.net)
#    Marcin Swieczkowski (scatman@bu.edu)
#
# Shows current track information for Spotify

# metadata
# <bitbar.title>Spotify Now Playing</bitbar.title>
# <bitbar.version>v1.2</bitbar.version>
# <bitbar.author>Marcin S., Jason Tokoph</bitbar.author>
# <bitbar.author.github>jtokoph</bitbar.author.github>
# <bitbar.desc>Display currently playing Spotify song. Play/pause, skip forward, skip backward.</bitbar.desc>
# <bitbar.image>http://i.imgur.com/y1SZwfq.png</bitbar.image>

# Change to the directory where your bitbar plugins are
USER_PATH="/Users/francesco/Documents/BitBar Plugins"

# Comment the following line to disable showing times.
SHOW_TIME=1

# By default we remove anything after " - ", as it usually is stuff like
# "Remastered", "Single Version", or other garbage that Spotify likes to
# include.
#
# Comment out this line if you want the full track names.
CLEAN_TRACK_NAMES=1
# Comment out this line if you want the full album names.
CLEAN_ALBUM_NAMES=1

# The length of a track/artist name after which to truncate.
TRUNC_LEN=25
# String used when replacing truncated text.
TRUNC_SUFFIX=" ..."

# Send a series of semicolon-delimited commands to Spotify
function tellspotify() {
  commands="$(echo "$1" | tr ";" "\\n")"

  osascript -e "
            tell application \"Spotify\"
                $commands
            end tell";
}

## Handle early-return cases

if [ "$1" = 'launch' ]; then
  tellspotify 'activate'
  exit
fi


if [ "$1" = 'quit' ]; then
  osascript -e 'quit app "BitBar"'
  exit
fi


if [ "$1" = 'folder' ]; then
  open "$USER_PATH"
  exit
fi

first="$(echo "$1" | head -n 1 | awk '{print $1;}')"
case "$first" in
  'playpause' | 'previous' | 'next' | 'set')
    tellspotify "$1"
    exit
esac

if [ "$(osascript -e 'application "Spotify" is running')" = "false" ]; then
  echo "♫"
  echo "---"
  echo "Spotify is not running"
  echo "Launch Spotify | bash='$0' param1=launch terminal=false"
  exit
fi

## Get Spotify info

state=$(tellspotify 'player state as string');
track=$(tellspotify 'name of current track as string');
artist=$(tellspotify 'artist of current track as string');
album=$(tellspotify 'album of current track as string');



##__________ ARTWORK
## retrieve artwork url and saves it to 'artworklnk'
artworklnk=$(tellspotify 'artwork url of current track as string');
## opens the txt file where the last artwork url is
oldartlnk=$(cat "$USER_PATH/spotifytemp/artwork.txt")
## if the url is different
if [ "$artworklnk" != "$oldartlnk" ]; then
 ## saves the new artwork in the file
  echo "$artworklnk" > "${USER_PATH}/spotifytemp/artwork.txt"
  ## downloads the new artwork in the temp.jpg
  curl "$artworklnk" 2>/dev/null > "${USER_PATH}/spotifytemp/temp.jpg"
  # converts the file to 200x200
  sips -z 500 500 "${USER_PATH}/spotifytemp/temp.jpg" > /dev/null 2> /dev/null
fi
# set the artwork img in the 'artwork' variable
artwork=$( base64 "${USER_PATH}/spotifytemp/temp.jpg")




# Handle last early-return case (needed $track and $artist to look up lyrics).
if [ "$1" = 'lyrics' ]; then
  open "https://duckduckgo.com/?q=!ducky+genius+lyrics+$track+$artist+site:genius.com+inurl:lyrics"
  exit
fi

if [ "$1" = 'imgclick' ]; then
  tellspotify 'activate'
  # open "https://genius.com/search?q=$album+$artist"
  exit
fi

if [ "$state" = "playing" ]; then
  state_icon="♫"
else
  state_icon="❚❚"
fi

# Clean up track and/or album names
if [[ $CLEAN_TRACK_NAMES ]]; then
  track="$(echo -e "${track/ - /\\n}" | head -n 1)"
  track="$(echo -e "${track/ (Remastered/\\n}" | head -n 1)"
fi
if [[ $CLEAN_ALBUM_NAMES ]]; then
  album="$(echo -e "${album/ - /\\n}" | head -n 1)"
  album="$(echo -e "${album/ (Remastered/\\n}" | head -n 1)"
fi

## Truncate track and artist
trunc_track=$track
if [ ${#trunc_track} -gt $TRUNC_LEN ];then
  trunc_track=${trunc_track:0:$TRUNC_LEN-${#TRUNC_SUFFIX}}$TRUNC_SUFFIX
fi

trunc_artist=$artist
if [ ${#trunc_artist} -gt $TRUNC_LEN ];then
  trunc_artist=${trunc_artist:0:$TRUNC_LEN-${#TRUNC_SUFFIX}}$TRUNC_SUFFIX
fi

# Get position and duration of track
if [[ $SHOW_TIME ]]; then
  position=$(osascript -e \
                       "tell application \"Spotify\"
                            set pos_sec to player position
                            set time_min to (pos_sec / 60 div 1) as text
                            set raw_sec to (pos_sec mod 60 div 1) as text
                            if length of raw_sec is greater than 1 then
                                set time_sec to raw_sec
                            else
                                set time_sec to \"0\" & raw_sec
                            end if
                            return time_min as text & \":\" & time_sec as text
                        end tell");
  duration=$(osascript -e \
                       "tell application \"Spotify\"
                            set total_sec to (duration of current track / 1000) as text
                            set time_min to (total_sec / 60 div 1) as text
                            set raw_sec to (total_sec mod 60 div 1) as text
                            if length of raw_sec is greater than 1 then
                                set time_sec to raw_sec
                            else
                                set time_sec to \"0\" & raw_sec
                            end if
                            return time_min as text & \":\" & time_sec as text
                        end tell");
fi

## Print the display

echo "$state_icon $trunc_track - $trunc_artist $state_icon"
echo "---"

echo "| image=$artwork bash='$0' param1=imgclick terminal=false"
echo "---"


echo -e "Track:\\t$track"
echo -e "Artist:\\t$artist"
echo -e "Album:\\t$album"
echo "---"

if [[ $SHOW_TIME ]]; then
  echo "${position} / ${duration}"
  echo '---'
fi

if [ "$state" = "playing" ]; then
  echo -e "❚❚\\tPause | bash='$0' param1=playpause terminal=false refresh=true"
  echo -e "↩\\tPrevious | bash='$0' param1='set player position to 0;previous track' terminal=false refresh=true"
  echo -e "↪\\tNext | bash='$0' param1='next track' terminal=false refresh=true"
  echo -e "🔙\\tReplay | bash = '$0' param1='set player position to 0' terminal=false"
else
  echo -e "▶\\tPlay | bash='$0' param1=playpause terminal=false refresh=true"
  echo -e "↩\\tPrevious | bash='$0' param1='set player position to 0;previous track;play' terminal=false refresh=true"
  echo -e "↪\\tNext | bash='$0' param1='next track;play' terminal=false refresh=true"
  echo -e "🔙\\tReplay | bash = '$0' param1='set player position to 0;play' terminal=false refresh=true"
fi

echo '---'
echo -e "🎶\\tLyrics | bash='$0' param1='lyrics' terminal=false"
echo '---'

echo '---'
echo -e "📻\\tOpen Spotify | bash='$0' param1=launch terminal=false"

echo '---'
echo -e "↻\\tRefresh | refresh=true"

echo '---'
echo -e "📁\\tOpen Plugins Folder | bash='$0' param1=folder terminal=false"

echo '---'
echo -e "🛑\\tQuit BitBar | bash='$0' param1=quit terminal=false"


