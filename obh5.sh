#!/bin/bash

# obh.sh - Move up and move down

# OBhelper - An application to help manage the Openbox static menu
# Started: 29 August 2021         Updated: 14th October 2021
# Elizabeth Mills

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

#    A copy of the GNU General Public License is available from:
#              the Free Software Foundation, Inc.
#                51 Franklin Street, Fifth Floor
#                   Boston, MA 02110-1301 USA

function MoveUp # Finds the landing index point for the selected item
{  # Then calls RebuildArray to process the move via temporary file temp.obh
   MovingObject=$1 # Index of selected object's 1st element in array
   MovingObjectType=${OBfile[${MovingObject}]:1:4}
   items=${#OBfile[@]}   # Count records in the array
   if [ $MovingObject -lt 3 ]; then
      ShowMessage "Objects cannot move out of Openbox menu"
      return 1
   fi
   # First find a landing point that is on top of the object above...
   LandingPoint=$((MovingObject-1))  # Start one line above the moving object

   while true
   do
      Item=${OBfile[${LandingPoint}]}           # Load previous line
      ItemType=${Item:1:4}                      # Check its type
      # If MovingObjectType is separator ItemType must be <menu or <item
      if [ $MovingObjectType == "sepa" ] && [ $ItemType != "menu" ] && [ $ItemType != "item" ] && [ $ItemType != "sepa" ]; then           # ie: not the top of an object)
         LandingPoint=$((LandingPoint-1))   # ... keep going.
      else                                  # All other situations
         case $ItemType in
         "sepa"|"item"|"menu"|"/men") break ;;
         *) LandingPoint=$((LandingPoint-1))
         esac
      fi
   done
   # Now build temp.obh from the top of the array, then update the array
   RebuildArray $MovingObject $LandingPoint "Up"

   return 0
} # End MoveUp

function MoveDown # Finds the landing index point for the selected item
{  # Then calls RebuildArray to process the move via temporary file temp.obh
   MovingObject=$1 # Index of selected object's 1st element in array
   MovingObjectType=${OBfile[${MovingObject}]:1:4}
   items=${#OBfile[@]}   # Count records in the array
   if [ $MovingObject -eq $items ]; then
      ShowMessage "Objects cannot move out of the Openbox menu"
      return 1
   fi

   # Find the end index of the moving object
   if [ $MovingObjectType == "sepa" ]; then  # If moving object is separator,
      EndIndex=$MovingObject                 # end index is the same as start
   else
      FindEndIndex $MovingObject             # Returns last line of object
      EndIndex=$?
   fi
   StartStaticObject=$EndIndex               # Start of the 'static' object
   FindEndIndex $StartStaticObject           # Returns last line of it
   LandingPoint=$?                           # This is used for RebuildArray
   # Now build temp.obh from the top of the array, then update the array
   RebuildArray $MovingObject $LandingPoint "Down"
   return 0
} # End MoveDown

function RebuildArray { # Calls functions to rebuild the array
   local MovingObject=$1      # Index of the moving object
   local LandingPoint=$2      # Index of its new placement
   local Direction=$3         # "Up" or "Down"
   local EndIndex=0           # Current location of the last line of the object

   MovingObjectRecord=${OBfile[${MovingObject}]}   # Header of the moving object
   MovingObjectType=${MovingObjectRecord:1:4}      # ... save its type
   rm temp.obh 2>/dev/null                         # Clear the workfile
   items=${#OBfile[@]}                             # Count array contents

   # 1) Find the endpoint of the selected object
   FindEndIndex $MovingObject                      # Get EndIndex
   EndIndex=$?
   # 2) Copy each element of the array to (new) locations in the temporary file
   PrepareNewLayout $MovingObject $LandingPoint $Direction
   # 3) Finally copy new temp.obh back into the array
   readarray -t OBfile < temp.obh

   return 0
} # End RebuildArray

function FindEndIndex # Find the endpoint of the selected object
{  local ObjectIndex=$1
   local ObjectType=${OBfile[${ObjectIndex}]:1:4}
  # local ObjectType=$2
   case $ObjectType in
   "sepa") # Separators are the simplest of all, being a single line
      EndIndex=$((ObjectIndex+1))
      ;;
   "item") # Items are simple enough, always having 5 elements ...
         # 1.<item, 2.<action, 3.<execute, 4.</action, 5.</item
       EndIndex=$((ObjectIndex+4))
      ;;
   "menu") # Menus are more complex, containing one or more other types
      menuLevel=0          # Ensure that closing tag belongs to this object
      j=${ObjectIndex}     # Start counting menu tags from the next element
      for (( j=$((j+1)); j < items; ++j ))
      do
         MenuComponentType=${OBfile[${j}]:1:5}  # Looking for menu or /menu
         # Break the loop when it reaches the matching closing menu tag
         if [ $MenuComponentType == "/menu" ] && [ $menuLevel -eq 0 ]; then
            EndIndex=$j
            break
         elif [ $MenuComponentType == "menu>" ]; then
            menuLevel=$((menuLevel+1))
         elif [ $MenuComponentType == "/menu" ]; then
            menuLevel=$((menuLevel-1))
         fi
      done
   esac
   return $EndIndex
} # End FindEndIndex

function PrepareNewLayout  # Save objects at new locations in temporary file
{  local MovingObject=$1   # Index of the first element of the moving object
   local LandingPoint=$2   # Index of the target location
   local Direction=$3      # Moving Up or Moving Down

   FindEndIndex $counter   # Find the end of the passed object
   local EndIndex=$?

   for (( i=0; i < items; ++i ))
      do
         if [ $i -eq $LandingPoint ]; then
         # If the landing point has been reached
            if [ $Direction == "Down" ]; then # First save the static object
               SaveStaticObject $((LandingPoint))
            fi
            case $MovingObjectType in  # Then save the moving object ...
            "sepa") # Separators are the simplest of all, being a single line
               echo ${OBfile[${MovingObject}]} >> temp.obh
               ;;
            "item") SaveAnItem $MovingObject
               ;;
            "menu") SaveAMenu $MovingObject
            esac
            if [ $Direction == "Up" ]; then # Save the static object after the
               SaveStaticObject $((LandingPoint))     # after the moving object
            fi
            # (a) If at the original location of the moving up object
         elif [ $i -ge $MovingObject ]&&[ $i -le $EndIndex ]; then
            continue                      # don't save the original object
         else
            # If not at Landing AND not at original home of object
            echo ${OBfile[${i}]} >> temp.obh # Save the record
         fi
      done
} # End PrepareNewLayout

function SaveStaticObject  # Ensures that the whole static object is saved
{  local counter=$1        # Start index of the static object
   local StaticObjectType=${OBfile[${counter}]:1:4}
   case $StaticObjectType in
      "sepa") echo ${OBfile[${counter}]} >> temp.obh
         ;;
      "item") SaveAnItem $counter
         ;;
      "menu") SaveAMenu $counter
   esac
} # End SaveStaticObject

function SaveAnItem {   # Loops through array elements containing an item
                        # adding them to the temp file
   local counter=$1           # Content of item = 1.<item ... (header tag)
   local limit=$((counter+4)) # 2.<action, 3.<execute, 4.</action, 5.</item
   while [ $counter -le $limit ]
   do
      echo ${OBfile[${counter}]} >> temp.obh
      counter=$((counter+1))
   done
}

function SaveAMenu { # Loops through array elements containing a menu
                     # adding them to the temp file
   local counter=$1
   FindEndIndex $counter   # Find the end of the passed object
   local limit=$?
   for (( counter; counter <= limit; ++counter ))
   do
      echo ${OBfile[${counter}]} >> temp.obh
   done
}