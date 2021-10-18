#!/bin/bash

# obh3.sh - Input and output functions

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

# Depends: Yad (sudo apt install yad)

function ShowList { # Use Yad to display the file contents in a listbox
   while true
   do
      selected=$(cat display.obh | yad --list       \
         --center --width=200 --height=500          \
         --text="Select an object from this list, then click a button" \
         --text-align=center        \
         --title="OBhelper"         \
         --search=column=0          \
         --column="":HD             \
         --column="Label"           \
         --column="Type"            \
         --column="Action"          \
         --column="Execute"         \
         --button=gtk-quit:1        \
         --button="New Menu":2      \
         --button="New Item":4      \
         --button="New Separator":6 \
         --button=gtk-delete:8      \
         --button=gtk-edit:10       \
         --button=gtk-go-up:12      \
         --button=gtk-go-down:14    \
         --button=gtk-save:16       \
         --separator=":")
      buttonPressed=$?                       # Save button number
      i=$(echo "$selected" | cut -d':' -f1)    # Save record number
      case $buttonPressed in
      1) return 1 ;;                         # Quit
      2) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddMenu "$i"
         fi ;;
      4) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddItem "$i"
         fi ;;
      6) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddSeparator "$i"
         fi ;;
      8) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            DeleteObject "$i"
         fi ;;
      10) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            EditObject "$i"
         fi ;;
      12) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            MoveUp "$i"
         fi ;;
      14) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            MoveDown "$i"
         fi ;;
      16) SaveTheArray
         mv "$XmlPath" "$XmlPath.safe"
         mv check.obh "$XmlPath"
         ShowMessage "Your work has been saved to $XmlPath"
       ;;
      *) return 1
      esac
      MakeFile    # Rebuild display.obh
   done
   return 0
} # End ShowList

function EditItem { # Load, edit and save the record
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo "${OBfile[$OBID]}" | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((OBID+1)) # Read next line (removing quotes and '>'
   Action=$(echo "${OBfile[$element]}" | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((element+1))  # Read next line to get the execute command
   Execute=$(echo "${OBfile[$element]}" | cut -d'>' -f2 | cut -d'<' -f1)
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter item details'     \
      --field='Label'                  \
      --field='Action':RO              \
      --field='Execute'                \
         "$Label" "Execute" "$Execute")
   if [ $? -eq 1 ]; then return 1; fi    # 'Cancel' was pressed
   # save to array   ...
   item=$(echo "$Gstring" | cut -d'|' -f1)
   Label=$(printf "<item label=\"%s\">" "$item")
   item=$(echo "$Gstring" | cut -d'|' -f2)
   Action=$(printf "<action name=\"%s\">" "$item")
   item=$(echo "$Gstring" | cut -d'|' -f3)
   Execute=$(printf "<execute>%s</execute>" "$item")

   OBfile[$OBID]="$Label"  # First element is
   advance=$((OBID+1))     # Advance to next related element
   OBfile[$advance]="$Action"
   advance=$((advance+1))     # Advance to next related element
   OBfile[$advance]="$Execute"
   return 0
} # End EditItem

function EditMenu  # Load, edit and save the record
{
   OBID=$1     # $1 is array record number
   # Extract ID (removing quotes)
   MenuID=$(echo "${OBfile[$OBID]}" | sed -e 's/"//g' | cut -d'=' -f2 | cut -d'-' -f3 | cut -d' ' -f1)
   # Extract Label (removing quotes and '>')
   Label=$(echo "${OBfile[$OBID]}" | cut -d'=' -f3 | cut -d'-' -f3 | sed -e 's/[">]//g')
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter menu details'     \
      --text-align=center              \
      --field='Label'                  \
      --field='ID'                     \
         "$Label" "$MenuID")
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   MenuID=$(echo "$Gstring" | cut -d'|' -f2)      # Extract the ID
   CheckMenuID "$MenuID" "$OBID"  # Check if number already used
   if [ $? -ne 0 ]; then EditMenu "$OBID"; fi  # If so, restart this function
   # <menu id="root-menu-68322" label="Titles">
   Label=$(echo "$Gstring" | cut -d'|' -f1)
   item=$(printf "<menu id=\"root-menu-%s\" label=\"%s\">" "$MenuID" "$Label")
   OBfile[$OBID]="$item"
   return 0
} #  EditMenu

function EditSeparator {  # Load, edit and save the separator
               # $1 is array record number
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo "${OBfile[$OBID]}" | cut -d'=' -f2 | sed -e 's/["/>]//g')
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter separator label'  \
      --text-align=center              \
      --field='Label' "$Label")
   if [ $? -eq 1 ]; then return; fi    # 'Cancel' was pressed
   Label=$(echo "$Gstring" | cut -d'|' -f1)
   item=$(printf "<menu id=\"root-menu-%s\" label=\"%s\">" "$MenuID" "$Label")
   OBfile[$OBID]=$item
   return 0
} # End EditSeparator

function EditObject { # Choose action based on type of object
                        # $1 is selected object's index in the array
   item=${OBfile[${1}]:1:4}
   case $item in
   "menu") EditMenu "$1"  # Load menu fields, edit and save
   ;;
   "item") EditItem "$1"  # Load item fields, edit and save
   ;;
   "sepa") EditSeparator "$1"  # Load separator fields, edit and save
   ;;
   *) return 1            # Data error
   esac
   # Update temp.obh
   return 0
} # End EditObject

function ShowMessage {   # Display a message in a pop-up window
   # $1 and $2 are optional lines of message text
   yad --text="$1
   $2"                        \
   --text-align=center        \
   --width=250 --height=100   \
   --center --on-top          \
   --buttons-layout=center    \
   --button=gtk-ok
} # End ShowMessage