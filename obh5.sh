#!/bin/bash

# obh.sh - Move up and move down
# Updated: 14th October 2021

# OBhelper - An application to help manage the Openbox static menu
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

function MoveUp # Check that the move is valid before calling
{               # the PrepareNewLayout function to process the move
   MovingObjectIndex=$1 # Index of selected object's first element in the array
   MovingObjectType=${OBfile[${MovingObjectIndex}]:1:4}
   if [ $MovingObjectIndex -lt 3 ]; then
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
         if [ $? -eq $MovingObjectIndex ]; then
            return 1
         else
            x=$((x+EndIndex-MovingObjectIndex))
         fi
      elif [ $x -eq $StartStaticObject ]; then  # The static object
         SaveAnObject $((StaticObjectIndex))
         if [ $? -eq $StaticObjectIndex ]; then
            return 1
         else
            x=$((x+EndStaticObject-StaticObjectIndex))
         fi
      else
         echo ${OBfile[${x}]} >> temp.obh       # All other records
      fi
   done
# Rebuild the array from the temp file
   readarray -t OBfile < temp.obh
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
         ;;
      "item") SaveAnItem $ObjectIndex
         ;;
      "menu") SaveAMenu $ObjectIndex
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