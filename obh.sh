#!/bin/bash

# obh.sh - Main module (preparation and system initiation)

# OBhelper - An application to help manage the Openbox static menu
# Version: 2021.1b - 18th October 2021
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
source debug.sh

# Global variables
Gnumber=0            # For returning integers from functions
Gstring=""           # For returning strings from functions
declare -a OBfile    # Array to hold a copy of the entire menu.xml file

# Data files
# menu.xml     -  The Openbox static menu configuration file
# temp.obh     -  Used during session to update OBfile array
# display.obh  -  Data from menu.xml in simpler format for user information

function Main {
   LoadArray "$XmlPath"                   # Load the main file into the array
   while true
   do
      MakeFile                            # Use array to prepare for display
      if [ $? -ne 0 ]; then break; fi     # If error or exit in MakeFile
      ShowList                            # Display simplified list
      if [ $? -ne 0 ]; then break; fi     # If error or exit in ShowList
   done
   # Check if temp.obh has changed from $XmlPath
   CompareFiles                           # Offers save if changed
   exit 0
} # End Main

if [ !$1 ]; then                       # Paths for testing or standard use
   # XmlPath="/home/$USER/.config/openbox/menu.xml"
   XmlPath="menu.xml"
else                                   # Path may be passed as argument
   XmlPath=$1
fi

if command -v yad >/dev/null 2>&1; then
   Main
else
   echo "OBhelper needs Yad for input and display."
   echo "Please use your system's software management application"
   echo "to install Yad. OBhelper will now exit."
   read -p "Please press [Enter]"
   exit
fi