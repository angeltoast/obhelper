#!/bin/bash

# obh3.sh - Input and output functions

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

function ShowList() { # Use Yad to display the file contents in a listbox
   while true
   do
      selected=$(cat display.obh | yad --list       \
         --center --width=150 --height=600          \
         --text="Select an object from this list, then click a button" \
         --text-align=center        \
         --title="OBhelper"         \
         --search-column=0          \
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
         --button=!gtk-go-up!:12    \
         --button=!gtk-go-down!:14  \
         --button=gtk-save:16       \
         --separator=":")
      buttonPressed=$?                       # Save button number
      i=$(echo $selected | cut -d':' -f1)    # Save record number
      case $buttonPressed in
      1) return 1 ;;                         # Quit
      2) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddMenu $i
         fi ;;
      4) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddItem $i
         fi ;;
      6) if [[ ! $selected ]]; then
            ShowMessage "Please select a line where the object is to go"
            continue
         else
            AddSeparator $i
         fi ;;
      8) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            DeleteObject $i
         fi ;;
      10) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            EditObject $i
         fi ;;
      12) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            MoveUp $i
         fi ;;
      14) if [[ ! $selected ]]; then
            ShowMessage "Please select an object"
            continue
         else
            MoveDown $i
         fi ;;
      16) SaveToFile ;;
      *) return 1
      esac
      MakeFile    # Rebuild display.obh
   done
   return 0
} # End ShowList

function FormatItem() { # Load, edit and save the record
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBfile[$OBID]} | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((OBID+1)) # Read next line (removing quotes and '>'
   Action=$(echo ${OBfile[$element]} | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((element+1))  # Read next line to get the execute command
   Execute=$(echo ${OBfile[$element]} | cut -d'>' -f2 | cut -d'<' -f1)
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
   item=$(echo $Gstring | cut -d'|' -f1)
   Label=$(printf "<item label=\"%s\">" "$item")
   item=$(echo $Gstring | cut -d'|' -f2)
   Action=$(printf "<action name=\"%s\">" "$item")
   item=$(echo $Gstring | cut -d'|' -f3)
   Execute=$(printf "<execute>%s</execute>" "$item")
   FormatOutput $OBID
   pip=$OBID         # Pip related elements
   OBfile[$pip]="$Gstring$Label"
   pip=$((pip+1))    # Next element
   OBfile[$pip]="    $Gstring$Action"
   pip=$((pip+1))    # Next elephant
   OBfile[$pip]="        $Gstring$Execute"
   return 0
} # End FormatItem

function FormatMenu()  # Load, edit and save the record
{
   OBID=$1     # $1 is array record number
   # Extract ID (removing quotes)
   MenuID=$(echo ${OBfile[$OBID]} | sed -e 's/"//g' | cut -d'=' -f2 | cut -d'-' -f3 | cut -d' ' -f1)
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBfile[$OBID]} | cut -d'=' -f3 | cut -d'-' -f3 | sed -e 's/[">]//g')
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter menu details'     \
      --text-align=center              \
      --field='Label'                  \
      --field='ID'                     \
         "$Label" "$MenuID")
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed
   MenuID=$(echo $Gstring | cut -d'|' -f2)      # Extract the ID
   CheckMenuID $MenuID $OBID                    # Check if number already used
   if [ $? -ne 0 ]; then FormatMenu $OBID; fi   # If so, restart this function
   # <menu id="root-menu-68322" label="Titles">
   Label=$(echo $Gstring | cut -d'|' -f1)
   item=$(printf "<menu id=\"root-menu-%s\" label=\"%s\">" "$MenuID" "$Label")
   FormatOutput $OBID
   OBfile[$OBID]="$Gstring$item"
   return 0
} #  FormatMenu

function FormatSep() {  # Load, edit and save the separator
               # $1 is array record number
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBfile[$OBID]} | cut -d'=' -f2 | sed -e 's/["/>]//g')
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter separator label'  \
      --text-align=center              \
      --field='Label' "$Label")
   if [ $? -eq 1 ]; then return; fi    # 'Cancel' was pressed
   # <separator label="Writing"/>
   Label=$(echo $Gstring | cut -d'|' -f1)
   item=$(printf "<menu id=\"root-menu-%s\" label=\"%s\">" "$MenuID" "$Label")
   FormatOutput $OBID
   OBfile[$OBID]="$Gstring$item"
   return 0
} # End FormatSep

function FormatOutput() {  # Try to indent edited records appropriately
                           # $1 is the selected record number
   items=${#OBfile[@]}           # Count records in the array
   menuLevel=0                   # Use menuLevel to manage indenting
   spaces=""
   for (( i=0; i < $items; ++i ))
   do
      if [ $i == $1 ]; then
         Gstring="$spaces"
         break
      fi
      item="${OBfile[$i]}"        # Read an element from the array
      item1=$(echo $item | cut -d'<' -f2 | sed -e 's/"//g') # Extract type
      header=${item1:0:3}
      case $header in
      "men") menuLevel=$((menuLevel+1))
            Indentation $menuLevel
            spaces="$Gstring"
            ;;
      "ite") continue
            ;;
      "sep") continue
            ;;
      "/me") menuLevel=$((menuLevel-1)) # Special action for end of menu
            Indentation $menuLevel
            spaces="$Gstring"
            ;;
      *) continue
      esac
   done
} # End FormatOutput

function EditObject() { # Choose action based on type of object TEST
               # $1 is selected object ID number
   OBID=$1
   item="$(echo ${OBfile[$OBID]} | cut -d'<' -f2 | cut -c1-4)"
   case $item in
   "menu") FormatMenu $OBID  #<menu id="root-menu-885940" label="Stumped Game">
   ;;
   "item") FormatItem $OBID  # Format and save
   ;;
   "sepa") FormatSep $OBID   # Prepare data for separator
   ;;
   *) return 1  # Data error
   esac
   return 0
} # End EditObject