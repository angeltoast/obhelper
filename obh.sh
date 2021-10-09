#!/bin/bash

# obh.sh - Main module

# OBhelper - An application to help manage the Openbox static menu
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

# Data files
# menu.xml  -  The Openbox static menu configuration file
# temp.obh  -  Used during session to update OBfile array

if [ !$1 ]; then     # Paths for testing and use
   # XmlPath="/home/$USER/.config/openbox/menu.xml"
   XmlPath="menu.xml"
else
   XmlPath=$1
fi

function Main() {
   if [[ ! -f check.obh ]]; then # Only display on first use
   ShowMessage "Welcome to OBhelper, the graphical assistant for managing your Openbox static menu configuration file." "Please note that changes you make during the session will not become permanent until you choose the 'Save' option."
   fi
   cp $XmlPath check.obh                  # For comparison on exit
   while true
   do
     # readarray -t OBfile < $XmlPath      # Read master file into array
      # ------------------ Added 09/10/21 --------------
      rm temp.obh 2>/dev/null
      # Trim records from master file into temp file
      cut -d'<' -f2 menu.xml > temp.obh
      # Read into array
      readarray -t OBfile < temp.obh
      rm temp.obh 2>/dev/null
      # Count records in the array
      items=${#OBfile[@]}
      # Add a leading '<' to each line
      for (( i=0; i < $items; ++i ))
      do
         item=${OBfile[${i}]}
         # Unless it has leading whitespace
         if [[ ${item:0:1} == " " ]]; then
            OBfile[${i}]="$item"
         else
            OBfile[${i}]="<$item"
         fi
      done
      # ----------- End added 09/10/21 ----------------
      MakeFile                            # Use array to prepare for display
      if [ $? -ne 0 ]; then break; fi     # If error in MakeFile
      ShowList                            # Display simplified list
      if [ $? -ne 0 ]; then break; fi     # If error in ShowList
   done
   # Check if temp.obh has changed from $XmlPath
   filecmp=$(cmp $XmlPath temp.obh 2>/dev/null)
   if [[ $filecmp ]]; then
      yad --text-info                     \
         --text "Your changes have not yet been saved. Save now?" \
         --center --on-top                \
         --text-align=center              \
         --width=250 --height=100         \
         --buttons-layout=center          \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$XmlPath not updated."
         return 0
      fi
      SaveToFile
   fi
   exit 0
} # End Main

function SaveToFile() { # TEST
   yad --text "Ok to save to $XmlPath?" \
      --center --on-top          \
      --text-align=center        \
      --width=250 --height=100   \
      --buttons-layout=center    \
      --button=gtk-no:1 --button=gtk-yes:0
   if [ $? -eq 0 ]; then
      rm display.obh 2>/dev/null
      items=${#OBfile[@]}              # Count records
      menuLevel=0
      spaces=""
      items=${#OBfile[@]}                 # Count records in the array
      for (( i=0; i < $items; ++i ))
      do
         item=${OBfile[${i}]}
         echo "$spaces$item" >> temp.obh        # Indented
         itemType=$(echo $item | cut -c2-5)     # Extract type
         # Prepare the record and add it to temporary file
         case $itemType in
         "menu"|"item"|"acti") # Increase indentation
               menuLevel=$((menuLevel+1))
               Indentation $menuLevel           # Returns spaces via Gstring
               spaces="$Gstring"
            ;;
         "/men"|"/act"|"exec") # Decrease indentation
               menuLevel=$((menuLevel-1))
               Indentation $menuLevel           # Returns spaces via Gstring
               spaces="$Gstring"
            ;;
         *) continue
         esac
      done
      mv temp.obh menu.xml 2>/dev/null
      openbox --reconfigure
   else
      ShowMessage "Changes not saved."
   fi
}

function ShowMessage() {   # Display a message in a pop-up window
                           # $1 and $2 are optional lines of message text
   yad --text="$1
   $2"                        \
   --text-align=center        \
   --center --on-top          \
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