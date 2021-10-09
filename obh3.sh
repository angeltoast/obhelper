#!/bin/bash

# obh3.sh - Input and output functions

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
  # FormatOutput $OBID (probably not a good idea
   advance=$OBID              # First element
   OBfile[$advance]="$Label"
   advance=$((advance+1))     # Advance to next related element
   OBfile[$advance]="$Action"
   advance=$((advance+1))     # Advance to next related element
   OBfile[$advance]="$Execute"
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

function FormatOutput() {  # Rebuild menu.xml from OBfile array
   menuLevel=0
   spaces=""
   items=${#OBfile[@]}     # Count records in the array
   for (( i=0; i < $items; ++i ))
   do
      item=${OBfile[${i}]}
   # Extract type
   itemType=$(echo $item | cut -c2-6 | sed -e 's/"//g')
Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO"
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
         spaces="Gstring"
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
   done

   return 0
} # End FormatOutput

function EditObject() { # Choose action based on type of object
                        # $1 is selected object's index in the array
   item="$(echo ${OBfile[${1}]} | cut -d'<' -f2 | cut -c1-4)"
   case $item in
   "menu") FormatMenu $1  # Load menu fields, edit and save
   ;;
   "item") FormatItem $1  # Load item fields, edit and save
   ;;
   "sepa") FormatSep $1   # Load separator fields, edit and save
   ;;
   *) return 1            # Data error
   esac
   # Update temp.obh
   return 0
} # End EditObject