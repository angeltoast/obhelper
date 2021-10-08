#!/bin/bash

# obh4.sh - Add and delete records

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

function AddMenu()  # TEST Final testing and bugfixes
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1
   # Display a form to enter menu details ...
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text='Enter details (ID must be a number unique to this menu)'  \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Menu Label'             \
      --field='Menu ID')
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   MenuID=$(echo $Gstring | cut -d'|' -f2)      # Extract the menu ID entered
   CheckMenuID $MenuID                          # Check if number already used
   if [ $? -ne 0 ]; then                        # Warn user
      ShowMessage "Menu ID already in use." "Please enter a different number."
      AddMenu                                   # Restart this function
   fi
   MenuLabel=$(echo $Gstring | cut -d'|' -f1)   # Extract the label
   Tidy                          # Delete the existing temp and display files
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
   items=${#OBfile[@]}                             # Count records
   for (( i=0; i < $items; ++i ))
   do
      if [ $OBID ] && [ $i -eq $OBID ]; then continue; fi # Ignore if editing
      if [[ ${OBfile[$i]} == *"$MenuID"* ]]; then        # If substring matches
         ShowMessage "Menu ID is already in use;" "Please use a different ID"
         return 1
      fi
   done
} # End CheckMenuID

function AddItem()  # TODO Use copy of AddMenu
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
   Tidy                          # Delete the existing temp and display files
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
}

function AddSeparator()  # TODO Can include label
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
   ItemLabel=$(echo $Gstring)    # Extract the label
   Tidy                          # Delete the existing temp and display files
   items=${#OBfile[@]}           # Count records in OBfile array
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
}

function DeleteObject()
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1
   Item=${OBfile[${ArrayElement}]}     # Find in array
   ItemType=$(echo $Item | cut -c5 | cut -d'<' -f2)
   ItemLabel="$(echo $Item | cut -d'=' -f3 | sed -e 's/[">]//g')"
   items=${#OBfile[@]}                 # Count records in the array
   # Determine if the object is a menu, item or separator
   case $ItemType in
   "menu") StartNumber=$ArrayElement
         EndNumber=$ArrayElement
      ItemLabel="$(echo $Item | cut -d'=' -f3 | sed -e 's/[">]//g')"
      menuLevel=0                   # Use menuLevel to manage indenting, and
      spaces=""                     # to detect menu opening and closing tags
      for (( i=$((StartNumber+1)); i < $items; ++i ))
      do # Display from the record after the selected menu header
         recordType=$(echo ${OBfile[${i}]} | cut -d'<' -f2 | cut -d' ' -f1)
         executeType=${recordType:0:7} # Looking for the matching closing tag
         if [ $recordType == "/menu>" ] && [ $menuLevel -eq 0 ]; then
            EndNumber=$i   # This is the matching </menu> tag, so save the number
            break          # ... and exit the loop
         fi
         FormatRecordForDisplay "${OBfile[${i}]}" $menuLevel "$spaces"
         menuLevel=$Gnumber
         spaces="$Gstring"
      done
      ShortList                     # Display all contents of the menu
      selected=$?                   # 0=Cancel 1=All 2=Header 252=Window closed
      case $selected in
      252) ShowMessage "$ItemLabel not deleted."
         return 0
      ;;
      0) ShowMessage "$ItemLabel not deleted."
         return 0
      ;;
      1) # Delete all
         yad --text "Delete the $ItemLabel menu and contents? Are you sure" \
            --center --on-top          \
            --width=250 --height=100   \
            --buttons-layout=center    \
            --button=gtk-no:1 --button=gtk-yes:0
         if [ $? -ne 0 ]; then
            ShowMessage "$ItemLabel not deleted."
            return 1
         fi
         Tidy
         # The loop will not save any records from the start to the finish
         for (( i=0; i < $items; ++i ))
         do # Start at top of array, ignoring all from menu start to end
            if [ $i -ge $StartNumber ] && [ $i -le $EndNumber ]; then
               continue
            else
               echo "${OBfile[${i}]}" >> temp.obh
            fi
         done
      ;;
      2) # Delete the opening and closing tags only
         yad --text "Delete the $ItemLabel menu, leaving the contents? Are you sure" \
            --center --on-top          \
            --width=250 --height=100   \
            --buttons-layout=center    \
            --button=gtk-no:1 --button=gtk-yes:0
         if [ $? -ne 0 ]; then
            ShowMessage "$ItemLabel not deleted."
            return 1
         fi
         Tidy
         # The loop will copy all records between the start and finish
         for (( i=0; i < $items; ++i ))
         do # Start at top of array
            if [ $i -eq $StartNumber ] || [ $i -eq $EndNumber ]; then
               continue                # Exclude selected menu
            else
               echo "${OBfile[${i}]}" >> temp.obh
            fi
         done
      ;;
      *) return 3
      esac
      ;;
   "item") yad --text "Are you sure you want to delete $ItemLabel?" \
         --center --on-top          \
         --width=250 --height=100   \
         --buttons-layout=center    \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$ItemLabel not deleted."
         return 1
      fi
      Tidy
      # Save all until StartNumber, then ignore all until
      # the first </item> is encountered
      for (( i=0; i < $items; ++i ))
      do # Start at top of array, ignoring all from menu start to end
         FindEnd=$(echo ${OBfile[${i}]} | cut -c1-6)  # </item
         if [ $i -ge $StartNumber ]; then
            if [ $FindEnd == "</item" ]; then
               StartNumber=$((items+1))    # No further records will be skipped
               continue
            fi
         else
            echo "${OBfile[${i}]}" >> temp.obh
         fi
      done
      ;;
   "sepa") yad --text "Are you sure you want to delete $ItemLabel?" \
      --center --on-top          \
      --width=250 --height=100   \
      --buttons-layout=center    \
      --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$ItemLabel not deleted."
         return 1
      fi
      Tidy
      for (( i=0; i < $items; ++i ))
      do                                     # Rewrite menu.xml from the array
         if [[ $i -eq $ArrayElement ]]; then # Ignore the item
            continue
         else
            echo "${OBfile[${i}]}" >> temp.obh
         fi
      done
      ;;
   *) return 1
   esac
   # And rebuild the array...
   readarray -t OBfile < temp.obh    # Read working file into array
   return 0
} # End DeleteObject

function ShortList() # Use Yad to display the file contents in a listbox
{  # Items are only displayed for information. They are not selectable.
   cat display.obh | yad --list       \
      --center --width=750 --height=300       \
      --text="The menu contains the following items. Do you wish to delete them all, or just the menu header?"          \
      --text-align=center        \
      --title="OBhelper"         \
      --search-column=0          \
      --column="":HD             \
      --column="Label"           \
      --column="Type"            \
      --column="Action"          \
      --column="Execute"         \
      --no-selection             \
      --buttons-layout=center    \
      --button="Cancel":0        \
      --button="Delete All":1    \
      --button="Delete Menu Header":2
   selected=$?
   return $selected
} # End ShortList