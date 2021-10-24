#!/bin/bash

# obh.sh

# OBhelper - An application to help manage the Openbox static menu
# Version: 2021.1c - 208th October 2021
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

# Global variables
Gnumber=0            # For returning integers from functions
Gstring=""           # For returning strings from functions
declare -a OBfile    # Array to hold a copy of the entire menu.xml file

# Data files
# menu.xml     -  The Openbox static menu configuration file
# temp.obh     -  Used during session to update OBfile array
# display.obh  -  Data in simpler format for user information

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

function AddMenu # Accept user input, rebuild temp.obh & copy to OBfile
{
   ArrayElement=$1   # Position in the array of the new menu
   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Menu Label'             \
      --field='Menu ID'                \
      --text='Enter details (ID must be a number unique to this menu)')
   if [ $? -eq 1 ]; then return 0; fi        # 'Cancel' was pressed

   MenuID=$(echo "$Gstring" | cut -d'|' -f2)   # Extract the menu ID entered
   if CheckMenuID "$MenuID"; then                      # Check if number already used
  # if [ $? -ne 0 ]; then                     # Warn user
      ShowMessage "The ID $MenuID is already in use." "Please enter a different number."
      AddMenu $ArrayElement    # Restart this function
   fi
   MenuLabel=$(echo $Gstring | cut -d'|' -f1) # Extract the label
   rm temp.obh 2>/dev/null                   # Clear temp.obh for re-use
   items=${#OBfile[@]}                       # Count records in OBfile array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<menu id=\"root-menu-$MenuID\" label=\"$MenuLabel\">" >> temp.obh
         echo "<item label=\"Item\">" >> temp.obh           # Including a
         echo "<action name=\"Execute\">" >> temp.obh       # dummy item
         echo "<execute>Action</execute>" >> temp.obh
         echo "</action>" >> temp.obh
         echo "</item>" >> temp.obh
         echo "</menu>" >> temp.obh
         SaveAnObject $i   # Check and save the original object at this index
         AddedLines=$?     # SaveAnObject returns number of lines added
                           # Increment $i by the new object and the original
         i=$((AddedLines+7))
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done

   LoadArray "temp.obh"         # Rebuild the array from temp.obh
   return 0
} # End AddMenu

function CheckMenuID  # Check the array for any other menus with this ID
{
   MenuID=$1
   OBID=$2
   items=${#OBfile[@]}                                      # Count records
   for (( i=0; i < items; ++i ))
   do
      if [ $OBID ] && [ $i -eq $OBID ]; then continue; fi   # Ignore if editing
      if [[ ${OBfile[$i]} == *"$MenuID"* ]]; then           # If *substring* matches
         ShowMessage "Menu ID is already in use;" "Please use a different ID"
         return 1
      fi
   done
} # End CheckMenuID

function AddItem # Accept user input, rebuild temp.obh & copy to OBfile
{
   ArrayElement=$1   # Position in the array of the new item
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
   items=${#OBfile[@]}                          # Size of OBfile array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<item label=\"$ItemLabel\">" >> temp.obh
         echo "<action name=\"Execute\">" >> temp.obh
         echo "<execute>$ItemAction</execute>" >> temp.obh
         echo "</action>" >> temp.obh
         echo "</item>" >> temp.obh
         SaveAnObject $i   # Check and save the original object at this index
         AddedLines=$?     # SaveAnObject returns number of lines added
                           # Increment $i by the new object and the original
         i=$((AddedLines+5))
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done
   # And rebuild the array...
   LoadArray "temp.obh"    # Read working file into array
   return 0
} # End AddItem

function AddSeparator # Accept user input, rebuild temp.obh & copy to OBfile
{  # $1 is the position in the array of the selected item in display.obh
   ArrayElement=$1   # Position in the array for the new separator

   Gstring=$(yad --title='OBhelper'    \
      --form --center --on-top         \
      --width=500 --height=200         \
      --text='Enter separator label'   \
      --text-align=center              \
      --buttons-layout=center          \
      --field='Label')
   if [ $? -eq 1 ]; then return 0; fi           # 'Cancel' was pressed

   SeparatorLabel=$(echo $Gstring | cut -d'|' -f1)   # Extract the label
   rm temp.obh 2>/dev/null                      # Clear the work file
   items=${#OBfile[@]}                          # Count records in array
   # Cycle through OBfile array adding each item to temp.obh
   for (( i=0; i < items; ++i ))
   do
      if [[ $i -eq $ArrayElement ]]; then # Insert new record at the right place
         echo "<separator label=\"$SeparatorLabel\"/>" >> temp.obh
         echo "${OBfile[${i}]}" >> temp.obh # Replace the original after it
      else
         echo "${OBfile[${i}]}" >> temp.obh
      fi
   done
   # And rebuild the array...
   LoadArray "temp.obh"    # Read working file into array
   return 0
} # End AddSeparator

function MoveUp # Check that the move is valid before calling
{               # the PrepareNewLayout function to process the move
   MovingObjectIndex=$1 # Index of selected object's first element in the array
   MovingObjectType=${OBfile[${MovingObjectIndex}]:1:4}
   if [ $MovingObjectIndex -lt 4 ]; then
      ShowMessage "Objects cannot move out of Openbox menu"
      return 1
   fi
   PrepareNewLayout $MovingObjectIndex "Up" # Process the move
   return 0
} # End MoveUp

function MoveDown # Check that the move is valid before calling
{                 # the PrepareNewLayout function to process the move
   MovingObjectIndex=$1 # Index of selected object's 1st element in array
   MovingObjectType=${OBfile[${MovingObjectIndex}]:1:4}
   items=${#OBfile[@]} # Count records in the array
   if [ $MovingObjectIndex -eq $items ]; then
      ShowMessage "Objects cannot move out of the Openbox menu"
      return 1
   fi
   PrepareNewLayout $MovingObjectIndex "Down" # Process the move
   return 0
} # End MoveDown

function PrepareNewLayout  # Save objects at new locations in temporary file
{  MovingObjectIndex=$1    # First element of the moving object
   Direction=$2            # Moving Up or Moving Down
# First establish the type of the moving object ...
   MovingObjectType=${OBfile[${MovingObjectIndex}]:1:4}
   # and the index of its last element ...
   if [ $MovingObjectType == "sepa" ]; then  # If moving object is separator,
      EndIndex=$MovingObjectIndex            # Only one line
   elif [ $MovingObjectType == "menu" ]||[ $MovingObjectType == "item" ]; then
      # The only other valid types
      FindEndIndex $MovingObjectIndex        # Returns last line of moving object
      EndIndex=$?
   else
      ShowMessage "Invalid record type being moved"
      return 1
   fi
# Use start and end indices of the objects to establish new positions
   if [ $Direction == "Up" ]; then  # Check each preceeding element to find
      FindStartIndex $((MovingObjectIndex-1))
      StaticObjectIndex=$? # Current start of the static object is here
      FindEndIndex $StaticObjectIndex        # Returns last line of static object
      EndStaticObject=$?
      LandingPoint=$StaticObjectIndex    # The moving object will land here
      # Calculate the length of the moving object and add to landing point,
      # and the new start of the static object will be after the moving object
      StartStaticObject=$((EndIndex-MovingObjectIndex+LandingPoint+1))
   elif [ $Direction == "Down" ]; then   # Static object will precede moving
      # object, so the current start of the moving object will be the new
      StartStaticObject=$MovingObjectIndex # starting point for the static object
      FindEndIndex $MovingObjectIndex  # Find last element of the moving object
      StaticObjectIndex=$?             # Bottom of the moving object
      StaticObjectIndex=$((StaticObjectIndex+1)) # First index below it
      FindEndIndex $StaticObjectIndex  # Find the bottom of the static object
      EndStaticObject=$?               # The landing point for the moving
      # object will be its old index plus the length of the static object...
      LandingPoint=$((EndStaticObject-StaticObjectIndex+MovingObjectIndex+1))
   else
      ShowMessage "Invalid value passed to function"
      return 1
   fi
   # $LandingPoint is where the moving object will land
   # $StartStaticObject is where the static object will land
   rm temp.obh 2>/dev/null                         # Clear the workfile
   items=${#OBfile[@]}                             # Count array contents
# Begin processing the records
   for (( x=0; x<items; ++x ))
   do
      if [ $x -eq $LandingPoint ]; then         # The moving object
         SaveAnObject $MovingObjectIndex
         x=$((x+EndIndex-MovingObjectIndex))
      elif [ $x -eq $StartStaticObject ]; then  # The static object
         SaveAnObject $((StaticObjectIndex))
         x=$((x+EndStaticObject-StaticObjectIndex))
      else
         echo ${OBfile[${x}]} >> temp.obh       # All other records
      fi
   done
# Rebuild the array from the temp file
   LoadArray "temp.obh"
} # End PrepareNewLayout

function FindStartIndex # Find the start point of an object
{
   local TailIndex=$1
   local TailTag=${OBfile[${TailIndex}]:1:5} # </menu, </item, or <separ
   case $TailTag in
   "separ") # Separators are the simplest of all, being a single line
      return $((TailIndex))
      ;;
   "/item") # Items are simple enough, always having 5 elements ...
         # 1.<item, 2.<action, 3.<execute, 4.</action, 5.</item
       return $((TailIndex-4))
      ;;
   "/menu") # Menus are more complex, containing one or more other types
      menuLevel=1       # Ensure that closing tag belongs to this object
      j=$TailIndex      # Start counting back from the tail element
      for ((j;j>0;--j))
      do
         MenuComponentType=${OBfile[${j}]:1:5}  # Looking for menu or /menu
         # Break the loop when it reaches the matching opening menu tag
         if [ "$MenuComponentType" == "menu " ] && [ $menuLevel -eq 0 ]; then
            return $j
         elif [ "$MenuComponentType" == "menu " ]; then # Exit a contained menu
            menuLevel=$((menuLevel+1))
         elif [ "$MenuComponentType" == "/menu" ]; then # Enter a contained menu
            menuLevel=$((menuLevel-1))
         fi
      done
      Debug "$BASH_SOURCE" "$FUNCNAME" "$LINENO"
   esac
   return $ObjectIndex     # Error returns the calling argument
} # End FindStartIndex

function FindEndIndex # Find the endpoint of an object
{  local ObjectIndex=$1
   local ObjectType=${OBfile[${ObjectIndex}]:1:4}
   local items=${#OBfile[@]}                        # Count array contents
   case $ObjectType in
   "sepa") # Separators are the simplest of all, being a single line
      return $ObjectIndex
      ;;
   "item")  # Items are simple enough, always having 5 elements ...
            # 1.<item, 2.<action, 3.<execute, 4.</action, 5.</item
      return $((ObjectIndex+4))
      ;;
   "menu") # Menus are more complex, containing one or more other types
      menuLevel=0          # Ensure that closing tag belongs to this object
      j=$((ObjectIndex+1))     # Start counting menu tags from the next element
      for ((j;j<items;++j))
      do
         MenuComponentType=${OBfile[${j}]:1:5}  # Looking for menu or /menu
         # Break the loop when it reaches the matching closing menu tag
         if [ "$MenuComponentType" == "/menu" ] && [ $menuLevel -eq 0 ]; then
            return $j
         elif [ "$MenuComponentType" == "menu " ]; then # Enter a contained menu
            menuLevel=$((menuLevel+1))
         elif [ "$MenuComponentType" == "/menu" ]; then # Exit a contained menu
            menuLevel=$((menuLevel-1))
         fi
      done
   esac
   return $ObjectIndex     # Error returns the calling argument
} # End FindEndIndex

function SaveAnObject  # Saves according to object type
{
   local ObjectIndex=$1
   local ObjectType=${OBfile[${ObjectIndex}]:1:4}
   case $ObjectType in
      "sepa") echo ${OBfile[${ObjectIndex}]} >> temp.obh
            return 1
         ;;
      "item") SaveAnItem $ObjectIndex
            return $?
         ;;
      "menu") SaveAMenu $ObjectIndex
            return $?
   esac
   return 0
} # End SaveAnObject

function SaveAnItem { # Loops through array elements containing an item
   local counter=$1           # Content of item = 1.<item ... (header tag)
   local limit=$((counter+4)) # 2.<action, 3.<execute, 4.</action, 5.</item
   while [ $counter -le $limit ]
   do
      echo ${OBfile[${counter}]} >> temp.obh
      counter=$((counter+1))
   done
   return $counter
}

function SaveAMenu { # Loops through array elements containing a menu
   local counter=$1
   FindEndIndex $counter   # Find the end of the passed object
   local limit=$?
   for (( counter; counter <= limit; ++counter ))
   do
      echo ${OBfile[${counter}]} >> temp.obh
   done
   return $counter
}

function DeleteObject
{  # $1 is the index in the array of the selected item in display.obh
   ArrayElement=$1
   StartNumber=$ArrayElement
   EndNumber=$ArrayElement
   Item=${OBfile[${ArrayElement}]}                 # Find in array
   ItemType=${Item:1:4}
   items=${#OBfile[@]}                             # Count records in the array

   case $ItemType in
   "menu")
      ItemLabel=$(echo "$Item" | cut -d'=' -f3 | sed -e 's/[">]//g')
      menuLevel=0                      # Use menuLevel to manage indenting, and
      spaces=""                        # to detect menu opening and closing tags
      rm display.obh 2>/dev/null
      for (( i=$((StartNumber+1)); i < items; ++i ))
      do # Display from the record after the selected menu header ItemType=${Item:1:6}
         ThisRecord=${OBfile[${i}]}
         recordType=${ThisRecord:1:6}
         # Looking for the matching closing tag
         if [ "$recordType" == "/menu>" ] && [ $menuLevel -eq 0 ]; then
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
         yad --text "Delete the $ItemLabel menu and contents?
                        Are you sure"  \
            --text-align=center        \
            --center --on-top          \
            --width=250 --height=100   \
            --buttons-layout=center    \
            --button=gtk-no:1 --button=gtk-yes:0
         if [ $? -ne 0 ]; then
            ShowMessage "$ItemLabel not deleted."
            return 1
         fi
         rm temp.obh 2>/dev/null
         # The loop will not save any records from menu start to menu finish
         for (( i=0; i < items; ++i ))
         do # Start at top of array, ignoring all from menu start to end
            if [ "$i" -ge "$StartNumber" ] && [ "$i" -le "$EndNumber" ]; then
               continue
            else
               echo "${OBfile[${i}]}" >> temp.obh
            fi
         done
      ;;
      2) # Delete the opening and closing tags only
         yad --text "Delete the $ItemLabel menu, leaving the contents?
                        Are you sure"  \
            --text-align=center        \
            --center --on-top          \
            --width=250 --height=100   \
            --buttons-layout=center    \
            --button=gtk-no:1 --button=gtk-yes:0
         if [ $? -ne 0 ]; then
            ShowMessage "$ItemLabel not deleted."
            return 1
         fi
         rm temp.obh 2>/dev/null
         # The loop will copy all records after menu start up to finish
         for (( i=0; i < items; ++i ))
         do # Start at top of array
            if [ $i -eq "$StartNumber" ] || [ $i -eq "$EndNumber" ]; then
               continue                # Exclude selected menu
            else
               echo "${OBfile[${i}]}" >> temp.obh
            fi
         done
      ;;
      *) return 3
      esac
      ;;
   "item") ItemLabel=$(echo "$Item" | cut -d'=' -f2 | sed -e 's/[">]//g')
      yad --text "Are you sure you want to delete
                  the '$ItemLabel' item?"   \
         --text-align=center        \
         --center --on-top          \
         --width=250 --height=100   \
         --buttons-layout=center    \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$ItemLabel not deleted."
         return 1
      fi
      rm temp.obh 2>/dev/null
      # Save all until StartNumber, then ignore all until the first </item>
      #                                                      is encountered
      for (( i=0; i < items; ++i ))
      do # Start at top of array, ignoring all from menu start to end
         FindEnd=$(echo "${OBfile[${i}]}" | cut -c1-6)  # </item
         if [ $i -ge "$StartNumber" ]; then
            if [ "$FindEnd" == "</item" ]; then
               StartNumber=$((items+1))    # No further records will be skipped
               continue
            fi
         else
            echo "${OBfile[${i}]}" >> temp.obh
         fi
      done
      ;;
   "sepa") ItemLabel=$(echo "$Item" | cut -d'=' -f2 | sed -e 's/[">/]//g')
      yad --text "Are you sure you want to delete
                  the '$ItemLabel' separator?"   \
         --text-align=center        \
         --center --on-top          \
         --width=250 --height=100   \
         --buttons-layout=center    \
         --button=gtk-no:1 --button=gtk-yes:0
      if [ $? -ne 0 ]; then
         ShowMessage "$ItemLabel not deleted."
         return 1
      fi
      rm temp.obh 2>/dev/null
      for (( i=0; i < items; ++i ))
      do                                     # Rewrite temp file from the array
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
   LoadArray "temp.obh"    # Read working file into array
   return 0
} # End DeleteObject

function ShortList # Display the selected items in a listbox # TEST
{  # Items are only displayed for information. They are not selectable.
   cat display.obh | yad --list           \
      --center --width=750 --height=300   \
      --text="The menu contains the following items. Do you wish to delete them all, or just the menu header?" \
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