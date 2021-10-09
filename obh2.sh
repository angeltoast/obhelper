#!/bin/bash

# obh2.sh - Preparation functions

# OBhelper - An application to help manage the Openbox static menu
# Started: 29 August 2021         Updated: 8 October 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

function MakeFile() {  # Use OBfile array to prepare the display file
   # Note: The display file excludes the XML declaration and the opening
   # "<openbox_menu>" and closing "</openbox_menu>" tags, as well as all
   # other closing tags (</menu> </item> </action>)
   # But those items are all in the OBfile array for consistency with menu.xml
   rm display.obh 2>/dev/null
   items=${#OBfile[@]}              # Count records in OBfile array
   menuLevel=0                      # To manage indenting
   spaces=""                        # Also for indenting
   echo "Preparing data for display"
   for (( i=0; i < $items; ++i ))
   do
      # Read an element from the array and send it for formatting
      FormatRecordForDisplay "${OBfile[${i}]}" "$menuLevel" "$spaces"
      if [ $? -eq 0 ]; then   # Function returns 1 for excluded items
         spaces=$Gstring
         menuLevel=$Gnumber
      fi
   done
   return 0
} # End MakeFile

function FormatRecordForDisplay() # Prepares and adds record to display.obh
{  # $1 = the whole record from the array; $2 = menuLevel; $3 = spaces
   # Sets Gstring to $spaces and Gnumber to $menuLevel
   menuLevel=$2
   spaces=$3
   # start by removing all '>'
   item=$(echo $1 | sed -e 's/>//g')
   # Extract content after the first '<' and remove quotes
   item1=$(echo $item | cut -d'<' -f2 | sed -e 's/"//g')
   header=${item1:0:3}
   # Prepare the record and add it to the display file (one line per field)
   case $header in
   "men") body=$(echo $item1 | cut -d'=' -f3 | sed -e 's/>//g')
         echo "$i" >> display.obh               # Index in menu.xml and array
         echo "$spaces$body" >> display.obh     # Indented
         echo "menu" >> display.obh
         echo " " >> display.obh
         echo " " >> display.obh
         Gnumber=$((menuLevel+1))
         Indentation $Gnumber                   # Also sets Gstring to spaces
      ;;
   "ite") body=$(echo $item1 | cut -d'=' -f2 | sed -e 's/>//g')
         # For 'item' get the rest of the record
         j=$((i+1))   # The next line is the action   (remove all '>')
         action=$(echo ${OBfile[${j}]} | sed -e 's/>//g')
         # Extract content after first '<'     and remove all quotes
         action=$(echo $action | cut -d'=' -f2 | sed -e 's/"//g')
         # Isolate the first word before the first space
         action=$(echo $action | cut -d' ' -f1)
         # The next line is the 'execute' command
         j=$((j+1))
         execute=$(echo ${OBfile[${j}]})
         # After '<' (remove all '>')
         execute=$(echo $execute | cut -d'<' -f2 | cut -d'>' -f2)
         echo "$i" >> display.obh               # Index in menu.xml and array
         echo "$spaces$body" >> display.obh     # Indented
         echo "item" >> display.obh
         echo "$action" >> display.obh
         echo "$execute" >> display.obh
      ;;
   "sep") body=$(echo $item1 | cut -d'=' -f2 | sed -e 's/[/]//')
         echo "$i" >> display.obh               # Index in menu.xml and array
         echo "$spaces$body" >> display.obh     # Indented
         echo "separator" >> display.obh
         echo " " >> display.obh
         echo " " >> display.obh
      ;;
   "/me")
         Gnumber=$((menuLevel-1))               # Special action for end of menu
         Indentation $Gnumber                   # Also sets Gstring to spaces
      ;;
   *) return 1
   esac
   return 0
} # End FormatRecordForDisplay

function Indentation() {   # Indentation according to menu level
   case $1 in
   0) Gstring="" ;;
   1) Gstring="      " ;;
   2) Gstring="           " ;;
   3) Gstring="                 " ;;
   4) Gstring="                        " ;;
   5) Gstring="                             " ;;
   6) Gstring="                                  "
   esac
   return 0
} # End Indentation