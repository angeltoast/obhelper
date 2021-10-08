#!/bin/bash

# obh4.sh - Add records

# OBhelper - A project written in bash to do what obmenu used to do
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

# Depends: Yad (sudo apt install yad)

function AddMenu()  # TEST
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1
   # Display a form to enter menu details ...
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Menu Label'             \
      --field='Menu ID'                \
      --text='Enter details (ID must be a number unique to this menu)')
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   MenuID=$(echo $Gstring | cut -d'|' -f2)      # Extract the menu ID entered
   CheckMenuID $MenuID                          # Check if number already used
   if [ $? -ne 0 ]; then                        # Warn user
      ShowMessage "Menu ID already in use." "Please enter a different number."
      AddMenu                                   # Restart this function
   fi
   MenuLabel=$(echo $Gstring | cut -d'|' -f1)   # Extract the label
   rm temp.obh 2>/dev/null
   items=${#OBfile[@]}           # Count records in OBfile array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < $items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<menu id=\"root-menu-$MenuID\" label=\"$MenuLabel\">" >> temp.obh
         echo "<item label=\"Item\">" >> temp.obh
         echo "<action name=\"Execute\">" >> temp.obh
         echo "<execute>Action</execute>" >> temp.obh
         echo "</action>" >> temp.obh
         echo "</item>" >> temp.obh
         echo "</menu>" >> temp.obh
         echo "${OBfile[${i}]}" >> temp.obh # And replace the original occupant
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done
   # And rebuild the array...
   readarray -t OBfile < temp.obh    # Read working file into array
   return 0
} # End AddMenu

function CheckMenuID()  # Check the array for any other menus with this ID
{
   MenuID=$1
   OBID=$2
   items=${#OBfile[@]}                                      # Count records
   for (( i=0; i < $items; ++i ))
   do
      if [ $OBID ] && [ $i -eq $OBID ]; then continue; fi   # Ignore if editing
      if [[ ${OBfile[$i]} == *"$MenuID"* ]]; then           # If substring matches
         ShowMessage "Menu ID is already in use;" "Please use a different ID"
         return 1
      fi
   done
} # End CheckMenuID

function AddItem()  # TEST
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1
   # Display a form to enter menu details ...
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text='Enter item details'      \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Item Label'             \
      --field='Action':RO              \
      --field='Command'                \
      "" "Execute" "")
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   ItemLabel=$(echo $Gstring | cut -d'|' -f1)   # Extract the label
   ItemAction=$(echo $Gstring | cut -d'|' -f3)  # Extract the action
   rm temp.obh 2>/dev/null
   items=${#OBfile[@]}           # Count records in OBfile array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < $items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<item label=\"$ItemLabel\">" >> temp.obh
         echo "<action name=\"Execute\">" >> temp.obh
         echo "<execute>$ItemAction</execute>" >> temp.obh
         echo "</action>" >> temp.obh
         echo "</item>" >> temp.obh
         echo "${OBfile[${i}]}" >> temp.obh # And replace the original occupant
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done
   # And rebuild the array...
   readarray -t OBfile < temp.obh    # Read working file into array
   return 0
} # End AddItem

function AddSeparator() # TEST
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1
   # Display a form to enter menu details ...
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text='Enter separator label'   \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Label')
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   ItemLabel=$(echo $Gstring)                   # Extract the label
   rm temp.obh 2>/dev/null
   items=${#OBfile[@]}                          # Count records in array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < $items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<separator label=\"$ItemLabel\"/>" >> temp.obh
         echo "${OBfile[${i}]}" >> temp.obh # And replace the original occupant
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done
   # And rebuild the array...
   readarray -t OBfile < temp.obh    # Read working file into array
   return 0
} # End AddSeparator