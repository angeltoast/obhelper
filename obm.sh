#!/bin/bash

# OBhelper - A project written in bash to do what obmenu used to do
# Started 29 August 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

# Depends: Yad (sudo apt install yad)

# Global variables
Gnumber=0            # For returning integers from functions
Gstring="y"          # For returning strings from functions
declare -a OBrecord  # Array to hold the entire menu.xml

if [ !$1 ]; then
   XmlPath="/home/elizabeth/CodingWorkshops/BashWorkshop/obm"
else
   XmlPath=$1
fi

LoadHeaders() {      # Collect contents of current menu.xml
   readarray -t OBrecord < $XmlPath/menu.xml    # Copy file into array
   MakeFile                            # Use array to prepare
   return 0                            #  the file for display
} # End LoadHeaders

MakeFile() {
   items=${#OBrecord[@]}               # Count records in the array
   menuLevel=0                         # To manage indenting
   spaces=""
   for (( i=0; i < $items; ++i ))
   do
     # if [[ $(echo ${OBrecord[${i}]}) == "<?"* ]] || [[ $(echo ${OBrecord[${i}]}) == "<o"* ]]; then continue; fi
      # Read an element from the array (remove all '>')
      item=$(echo ${OBrecord[${i}]} | sed -e 's/>//g')
      # Extract content after the first '<' and remove quotes
      item1=$(echo $item | cut -d'<' -f2 | sed -e 's/"//g')
      header=${item1:0:3}
      case $header in
      "men") body=$(echo $item1 | cut -d'=' -f3 | sed -e 's/>//g')
            echo "$i" >> display.list
            echo "$spaces$body" >> display.list
            echo "menu" >> display.list
            echo " " >> display.list
            echo " " >> display.list
            menuLevel=$((menuLevel+1))
            Inset $menuLevel
            spaces="$Gstring"
            ;;
      "ite") body=$(echo $item1 | cut -d'=' -f2 | sed -e 's/>//g')
            # For 'item' get the rest of the record
            j=$((i+1))   # The next line is the action   (remove all '>')
            action=$(echo ${OBrecord[${j}]} | sed -e 's/>//g')
            # Extract content after first '<'     and remove all quotes
            action=$(echo $action | cut -d'=' -f2 | sed -e 's/"//g')
            # Isolate the first word before the first space
            action=$(echo $action | cut -d' ' -f1)
            # The next line is the 'execute' command
            j=$((j+1))
            execute=$(echo ${OBrecord[${j}]})
            # After '<' (remove all '>')
            execute=$(echo $execute | cut -d'<' -f2 | cut -d'>' -f2)
            echo "$i" >> display.list
            echo "$spaces$body" >> display.list
            echo "item" >> display.list
            echo "$action" >> display.list
            echo "$execute" >> display.list
            ;;
      "sep") body=$(echo $item1 | cut -d'=' -f2 | sed -e 's/[/]//')
            echo "$i" >> display.list
            echo "$spaces$body" >> display.list
            echo "separator" >> display.list
            echo " " >> display.list
            echo " " >> display.list
            ;;
      "/me")
            menuLevel=$((menuLevel-1)) # Special action for end of menu
            Inset $menuLevel
            spaces="$Gstring"
            ;;
      *) continue
      esac
   done
} # End MakeFile

Inset() {   # Indentation according to menu level
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
} # End Inset

ShowList() {
   while true
   do
      selected=$(cat display.list | yad --list           \
         --center --width=150 --height=600               \
         --text="Select an item, then click a button"   \
         --text-align=center     \
         --title="OBhelper"      \
         --search-column=0       \
         --column="":HD          \
         --column="Name"         \
         --column="Type"         \
         --column="Action"       \
         --column="Execute"      \
         --button=gtk-quit:1     \
         --button=gtk-add:3      \
         --button=gtk-delete:2   \
         --button=gtk-edit:4     \
         --button=gtk-go-up:6    \
         --button=gtk-go-down:8  \
         --separator=":")
      buttonPressed=$?                       # Save button number
      i=$(echo $selected | cut -d':' -f1)    # Record number
      case $buttonPressed in
      0) return 0 ;;
      3) EntryForm;;
      2) DeleteObject $i ;;
      4) EditObject $i ;;
      6) MoveUp $i ;;
      8) MoveDown $i ;;
      *) return 1
      esac
      Tidy
      MakeFile    # Rebuild the display.list
   done
   return 0
} # End ShowList

DeleteObject() { # $1 is selected object line number
  # item="$(head -n $1 menu.xml | tail -n 1)"
  # Find in array
  # Identify enclosed objects and closing tag
  # If menu, ask if delete contents
  # Update array
  # Update display.list
  return 0
} # End DeleteObject

EditObject() { # Choose action based on type of object
               # $1 is selected object ID number
   OBID=$1
   item="$(echo ${OBrecord[$OBID]} | cut -d'<' -f2 | cut -c1-4)"
   case $item in
   "menu") FormatMenu $OBID  #<menu id="root-menu-885940" label="Stumped Game">
   ;;
   "item") FormatItem $OBID  # Format and save
   ;;
   "sepa") FormatSep $OBID   # Prepare data for EntryForm
   ;;
   *) return 1  # Data error
   esac
   return 0
} # End EditObject

FormatItem() { # Load, edit and save the record
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBrecord[$OBID]} | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((OBID+1)) # Read next line (removing quotes and '>'
   Action=$(echo ${OBrecord[$element]} | cut -d'=' -f2 | sed -e 's/[">]//g')
   element=$((element+1))  # Read next line to get the execute command
   Execute=$(echo ${OBrecord[$element]} | cut -d'>' -f2 | cut -d'<' -f1)
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter item details'     \
      --field='Label'                  \
      --field='Action':RO              \
      --field='Execute'                \
         "$Label" "Execute" "$Execute")
   if [ $? -eq 1 ]; then return; fi    # 'Cancel' was pressed
   # save to array   ...
   item=$(echo $Gstring | cut -d'|' -f1)
   Label=$(printf "<item label=\"%s\">" "$item")
   item=$(echo $Gstring | cut -d'|' -f2)
   Action=$(printf "<action name=\"%s\">" "$item")
   item=$(echo $Gstring | cut -d'|' -f3)
   Execute=$(printf "<execute>%s</execute>" "$item")
   FormatOutput $OBID
   pip=$OBID         # Pip related elements
   OBrecord[$pip]="$Gstring$Label"
   pip=$((pip+1))    # Next element
   OBrecord[$pip]="    $Gstring$Action"
   pip=$((pip+1))    # Next elephant
   OBrecord[$pip]="        $Gstring$Execute"
   return 0
} # End FormatItem

FormatMenu() { # Load, edit and save the record
               # $1 is array record number
   OBID=$1
   # Extract ID (removing quotes)
   MenuID=$(echo ${OBrecord[$OBID]} | sed -e 's/"//g' | cut -d'=' -f2 | cut -d'-' -f3 | cut -d' ' -f1)
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBrecord[$OBID]} | cut -d'=' -f3 | cut -d'-' -f3 | sed -e 's/[">]//g')
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text=' Enter menu details'     \
      --text-align=center              \
      --field='Label'                  \
      --field='ID'                     \
         "$Label" "$MenuID")
   if [ $? -eq 1 ]; then return; fi    # 'Cancel' was pressed
   # Check the array for any other menus with this ID
   MenuID=$(echo $Gstring | cut -d'|' -f2)
   items=${#OBrecord[@]}                     # Count records
   for (( i=0; i < $items; ++i ))
   do
      if [ $i -eq $OBID ]; then continue; fi # Ignore this record
      if [[ ${OBrecord[$i]} == *"$MenuID"* ]]; then # If substring matches
         ShowMessage "Menu ID is already in use;" "Please use a different ID"
         FormatMenu $OBID                          # Restart menu edit
      fi
   done
   # <menu id="root-menu-68322" label="Titles">
   Label=$(echo $Gstring | cut -d'|' -f1)
   item=$(printf "<menu id=\"root-menu-%s\" label=\"%s\">" "$MenuID" "$Label")
   FormatOutput $OBID
   OBrecord[$OBID]="$Gstring$item"
   return 0
} #  FormatMenu

FormatSep() {  # Load, edit and save the separator
               # $1 is array record number
   OBID=$1
   # Extract Label (removing quotes and '>')
   Label=$(echo ${OBrecord[$OBID]} | cut -d'=' -f2 | sed -e 's/["/>]//g')
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
   OBrecord[$OBID]="$Gstring$item"
   return 0
} # End FormatSep

FormatOutput() {  # Try to indent edited records appropriately
                  # $1 is the selected record number
   items=${#OBrecord[@]}           # Count records in the array
   menuLevel=0                     # Use menuLevel to manage indenting
   spaces=""
   for (( i=0; i < $items; ++i ))
   do
      if [ $i == $1 ]; then
         Gstring="$spaces"
         break
      fi
      item="${OBrecord[$i]}"        # Read an element from the array
      item1=$(echo $item | cut -d'<' -f2 | sed -e 's/"//g') # Extract type
      header=${item1:0:3}
      case $header in
      "men") menuLevel=$((menuLevel+1))
            Inset $menuLevel
            spaces="$Gstring"
            ;;
      "ite") continue
            ;;
      "sep") continue
            ;;
      "/me") menuLevel=$((menuLevel-1)) # Special action for end of menu
            Inset $menuLevel
            spaces="$Gstring"
            ;;
      *) continue
      esac
   done
}

MoveUp() { # $1 is selected object line number
  # item="$(head -n $1 menu.xml | tail -n 1)"
  # Take care to place outside other objects.
  # Copy the whole selected record into an array, then read each previous
  # line until you reach the the line prior to the top of the previous
  # record; save the line number, then start from the top of the array,
  # copying each record into a temp file until the saved line is reached.
  # Add the record from the temp array into the temp file, then resume
  # copying the remaining records into the temp file.
  # Finally rename the temp file as display.list
  return 0
} # End MoveUp

MoveDown() { # $1 is selected object line number
  # item="$(head -n $1 menu.xml | tail -n 1)"
  # Take care to place outside other objects.
  # Copy the whole selected record into an array, then read each next
  # line until you reach the the line after the bottom of the next
  # record; save the line number, then start from the top of the array,
  # copying each record into a temp file until the saved line is reached.
  # Add the record from the temp array into the temp file, then resume
  # copying the remaining records into the temp file.
  # Finally rename the temp file as display.list
  return 0
} # End MoveDown

BaleOut() {
   Gstring="exit"
   return 0
} # End BaleOut

Tidy() {    # Clear temporary files
   rm display.list 2>/dev/null
   rm temp.file 2>/dev/null
   return 0
} # End Tidy

ShowMessage() {   # ShowList a message in a pop-up terminal window
                  # $1 and $2 optional lines of message text
    xterm -T " Error" -geometry 90x10+300+250 -fa monospace -fs 10 -e "echo '$1' && echo '$2' && read -p 'Please press [Enter] ...'"
} # End DoMessage

Debug() {   # Insert at any point ...
            # echo " any variables "
            # Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO"
   read -p "In file: $1, function:$2, at line:$3"
   return 0
} # End Debug

Main() {
   until [ $Gstring == "exit" ]
   do
      Tidy
      LoadHeaders
      ShowList
      BaleOut
   done
   # Before exit, rewrite menu.xml from array and reconfigure openbox
   # First experiment with a temporary file
   items=${#OBrecord[@]}                              # Count records
   for (( i=0; i < $items; ++i ))
   do
      echo "${OBrecord[$i]}" >> temp.file
   done
   exit 0
} # End Main

Main