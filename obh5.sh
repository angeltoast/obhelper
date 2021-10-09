#!/bin/bash

# obh.sh - Move up and move down

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

function MoveUp() { # $1 is selected object line number TODO Not started
   ShowMessage "Move function not written yet"
  # OBID=$1
  # Extract ID (see other functions)
   # Take care with menus to move all contents
   # Take care with items within menus to not move beyond menu bounds
   # All types - take care to place outside other objects.
  # Copy the whole selected record into an array, then read each previous
  # line until you reach the the line prior to the top of the previous
  # record; save the line number, then start from the top of the array,
  # copying each record into another array until the saved line is reached.
  # Add the record from the temp array into the array, then resume
  # copying the remaining records into the temporary array.
  # Finally empty the main array and copy the temporary array into it.
  return 0
} # End MoveUp

function MoveDown() { # $1 is selected object line number TODO Not started
   ShowMessage "Move function not written yet"
  # OBID=$1
  # Extract ID (see other functions)
   # Take care with menus to move all contents
   # Take care with items within menus to not move beyond menu bounds
   # All types - take care to place outside other objects.
  # Copy the whole selected record into an array, then read each following
  # line until you reach the the line after the top of the next
  # record; save the line number, then start from the end of the array,
  # copying each record into another array until the saved line is reached.
  # Add the record from the temp array into the array, then resume
  # copying the remaining records into the temporary array.
  # Finally empty the main array and copy the temporary array into it.
  return 0
} # End MoveDown