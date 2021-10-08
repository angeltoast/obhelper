#!/bin/bash

# obh.sh - Main module

# OBhelper - A project written in bash to do what obmenu used to do
# Started: 29 August 2021         Updated: 6 October 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

# Depends: Yad (sudo apt install yad)

# Additional functions
source obh2.sh
source obh3.sh
source obh4.sh
source obh5.sh
source obh6.sh

# Global variables
Gnumber=0            # For returning integers from functions
Gstring=""           # For returning strings from functions
declare -a OBfile    # Array to hold a copy of the entire menu.xml file

if [ !$1 ]; then     # Paths for testing and use
   # XmlPath="/home/$USER/.config/openbox/menu.xml"
   XmlPath="menu.xml"
else
   XmlPath=$1
fi

function Main() {
   cp $XmlPath check.obh                  # For comparison on exit
   while true
   do
      Tidy                                # Remove any lingering work files
      readarray -t OBfile < $XmlPath      # Read master file into array
      MakeFile                            # Use array to prepare for display
      if [ $? -ne 0 ]; then break; fi     # If error in MakeFile
      ShowList
      if [ $? -ne 0 ]; then break; fi    # If error in ShowList
   done
   # Check if temp.obh has changed from $XmlPath
   filecmp=$(cmp $XmlPath check.obh)
   if [[ $filecmp ]]; then
      yad --text "Your changes have not yet been saved. Save now?" \
         --center --on-top                \
         --width=250 --height=100         \
         --buttons-layout=center          \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$XmlPath not updated."
         return 0
      fi
      SaveToFile
      openbox --reconfigure
   fi
   exit 0
} # End Main

function SaveToFile() { # TEST
   yad --text "Ok to save to $XmlPath?" \
      --center --on-top          \
      --width=250 --height=100   \
      --buttons-layout=center    \
      --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -eq 0 ]; then
         Tidy
         items=${#OBfile[@]}                    # Count records
         echo "${OBfile[0]}" > $XmlPath
         for (( i=1; i < $items; ++i ))
         do                                     # Rewrite menu.xml from the array
            echo "${OBfile[${i}]}" >> $XmlPath
         done
         # openbox --reconfigure
      else
         ShowMessage "Changes not saved."
      fi
}

function Tidy() {    # Clear temporary files
   rm display.obh 2>/dev/null
   cp temp.obh check.obh 2>/dev/null
   rm temp.obh 2>/dev/null
   return 0
} # End Tidy

function ShowMessage() {   # ShowList a message in a pop-up terminal window
                  # $1 and $2 optional lines of message text
   yad --text "$1"            \
   --center --on-top          \
   --width=500 --height=200   \
   --buttons-layout=center    \
   --button=gtk-ok
} # End ShowMessage

function Debug() {   # Insert at any point ...
      # echo " any variables "
      # Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO"
   read -p "In file: $1, function:$2, at line:$3"
   return 0
} # End Debug

Main