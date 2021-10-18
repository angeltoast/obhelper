#!/bin/bash

# obh2.sh - File preparation functions

# OBhelper - An application to help manage the Openbox static menu
# Updated: 18th October 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

function LoadArray  # Load a file into the array
{
   local FileName=$1
   local i=0
   while read -r line
   do
      OBfile[${i}]=$line
      i=$((i+1))
   done < "$FileName"
   return 0
}

function MakeFile {  # Use OBfile array to prepare the display file
   # Note: The display file excludes the XML declaration and the opening
   # "<openbox_menu>" and closing "</openbox_menu>" tags, as well as all
   # other closing tags (</menu> </item> </action>)
   # But those items are all in the OBfile array for consistency with menu.xml
   rm display.obh 2>/dev/null
   items=${#OBfile[@]}              # Count records in OBfile array
   menuLevel=0                      # To manage indenting
   spaces=""                        # Also for indenting
   for (( i=0; i < items; ++i ))
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

function FormatRecordForDisplay # Prepares and adds record to display.obh
{  # $1 = the whole record from the array; $2 = menuLevel; $3 = spaces
   # Sets Gstring to $spaces and Gnumber to $menuLevel
   Item=$1
   menuLevel=$2
   spaces=$3
   Type=${Item:1:4}
   # start by removing all '>' extract content after the first '<' and remove quotes
   Item=$(echo "$1" | sed -e 's/>//g' | cut -d'<' -f2 | sed -e 's/"//g')
   # Prepare the record and add it to the display file (one line per field)
   case $Type in
   "menu") body=$(echo "$Item" | cut -d'=' -f3 | sed -e 's/>//g')
         echo -e "$i\n$spaces$body\nmenu\n\n" >> display.obh
         Gnumber=$((menuLevel+1))
         Indentation $Gnumber             # Sets Gstring to spaces
      ;;
   "item") body=$(echo "$Item" | cut -d'=' -f2 | sed -e 's/>//g')
         j=$((i+2))                       # Grab the 'execute' command
         execute=$(echo "${OBfile[${j}]}" | cut -d'<' -f2 | cut -d'>' -f2)
         echo -e "$i\n$spaces$body\nitem\nexecute\n$execute" >> display.obh
      ;;
   "sepa") body=$(echo "$Item" | cut -d'=' -f2 | sed -e 's/[/]//')
         echo -e "$i\n$spaces$body\nseparator\n\n" >> display.obh
      ;;
   "/men")
         Gnumber=$((menuLevel-1))         # Special action for end of menu
         Indentation $Gnumber             # Sets Gstring to spaces
      ;;
   *) return 1
   esac
   return 0
} # End FormatRecordForDisplay

function Indentation { # Indentation according to menu level
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

function SaveTheArray # Build check.obh from OBfile array
{
   menuLevel=0
   spaces=""
   items=${#OBfile[@]}                    # Count records in the array
   rm check.obh 2>/dev/null               # Just in case
   for (( i=0; i < items; ++i ))
   do
      item=${OBfile[${i}]}
      echo -e "$spaces$item" >> check.obh
      Type=${item:1:4}                    # Extract type
      case $Type in                       # Maintain indentation
      "menu"|"item"|"acti") menuLevel=$((menuLevel+1))    # Increase for menu
            Indentation $menuLevel
            spaces="$Gstring"
         ;;
      "/men"|"/ite"|"/act") menuLevel=$((menuLevel-1))    # Decrease for end menu
            Indentation $menuLevel
            spaces="$Gstring"
      esac
   done
   return 0
} # End SaveTheArray

function CompareFiles   # Check if the array has changed from $XmlPath
{
   SaveTheArray         # Saves to check.obh
   filecmp=$(cmp "$XmlPath" check.obh)
   if [[ $filecmp ]]; then
      yad --text "Your changes have not yet been saved. Save now?" \
         --center --on-top                \
         --text-align=center              \
         --width=250 --height=100         \
         --buttons-layout=center          \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$XmlPath not updated."
         return 0
      fi
      mv "$XmlPath" "$XmlPath.safe"
      mv check.obh "$XmlPath"
      ShowMessage "Your work has been saved to $XmlPath"
   fi
   return 0
}

Tidy() { # Silently clear temporary files
   rm display.obh 2>/dev/null
   rm temp.obh 2>/dev/null
   return 0
} # End Tidy