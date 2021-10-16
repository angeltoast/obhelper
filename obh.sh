#!/bin/bash

# obh.sh - Main module (preparation and system initiation)

# OBhelper - An application to help manage the Openbox static menu
# Started: 29 August 2021         Updated: 14th October 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

# Depends: Yad or Zenity (sudo apt install yad)

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
# menu.xml     -  The Openbox static menu configuration file
# temp.obh     -  Used during session to update OBfile array
# display.obh  -  Data from menu.xml in simpler format for user information

function Main {
   Tidy
   cp $XmlPath check.obh               # For comparison on exit
   # Load menu.xml into the array
   i=0
   while read line
   do
      OBfile[${i}]=$line
      i=$((i+1))
   done < menu.xml
   # Then begin main loop
   while true
   do
      MakeFile                            # Use array to prepare for display
      if [ $? -ne 0 ]; then break; fi     # If error or exit in MakeFile
      ShowList                            # Display simplified list
      if [ $? -ne 0 ]; then break; fi     # If error or exit in ShowList
   done
   # Check if temp.obh has changed from $XmlPath
   CompareFiles
   Tidy
   exit 0
} # End Main

function Debug { # Insert at any point (without the hashes, obviously) ...
   # set -xv
      # echo " any variables "
      # Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO"
   read -p "In file: $1, function:$2, at line:$3"
  # set +xv
   return 0
} # End Debug

if command -v yad >/dev/null 2>&1; then
   Dialog="yad"
elif command -v $Dialog >/dev/null 2>&1; then
   Dialog="zenity"
else
   echo "OBhelper needs Yad to display results."
   echo "Please use your system's software management application"
   echo "to install Yad. OBhelper will now exit."
   read -p "Please press [Enter]"
   exit
fi

if [ !$1 ]; then                       # Paths for testing or standard use
   # XmlPath="/home/$USER/.config/openbox/menu.xml"
   XmlPath="menu.xml"
else                                   # Path may be passed as argument
   XmlPath=$1
fi

Main