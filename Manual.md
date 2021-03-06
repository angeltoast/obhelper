# OBhelper User Manual				updated: 18/10/2021
This manual has similar content to the wiki in the OBhelper Github repository.
If there are any differences, this file is the most recently updated.

-------------------------- **About OBhelper** ------------------------

Openbox has a static menu system that is usually called by a right-click of the mouse anywhere on the desktop. The menu can contain links to any applications you choose, all defined in a configuration file called menu.xml

The objective of OBhelper is to display the contents of that configuration file in a simplified scrollable list, so that any entry may be selected, then edited, deleted or moved up or down, or new entries may be inserted. OBhelper uses Yad to provide an interactive graphical display.

--------------------------- **Using OBhelper** ------------------------------

At startup, OBhelper has a row of buttons across the bottom, and a listbox showing all the various items in your menu.xml in a concise format. You just select an item, then click a button to perform any of the actions:

     Edit the object on that line
     Move the object on that line Up one step
     Move the object on that line Down one step
     Insert a new object on that line
     Delete the object on that line
     Save your changes to menu.xml
     Quit

*Save*
----
All your changes in a session are kept in a temporary file - your menu.xml file is not affected at all until you click the Save button. If you leave the session without saving, your changes will be discarded. So, if you delete something in the session and then regret it, all is not lost - just exit without saving.

There are three kinds of entry in the Openbox static menu:
   Menus
   Actions (also known as 'Items')
   Separators

*Menus*
-----
Menus can contain actions and sub-menus. OBhelper enables you to easily create and change menus. A new menu can be created inside an existing menu.

*Items*
-----
Items (actions) can exist inside menus, or they can be standalone.

*Separators*
----------
Separators help to headline different areas of your Openbox menu with helpful labels. Separators are always freestanding, outside all sub-menus.

*Adding a new object, or editing an existing one*
-----------------------------------------------
OBhelper presents a simple entry form. Just fill in the boxes.

Menus require a unique identification number. It can be any combination of numeric digits, as long as that combination is not used elsewhere in that menu.xml. Generally, it is best to keep it simple - three digits is probably enough for nearly every situation.

*Deleting an object*
------------------
If you choose to delete an object, a confirmation will be offered. If the selected object is a menu, you will also be offered the choice of deleting the contents as well, or just the enclosing menu.

*Moving*
------
'Move Up' or 'Move Down' will move the selected element up or down one line of the displayed list.

If an item at the top of a sub-menu is moved up, it will move up out of the menu; similarly if an item at the bottom of a sub-menu is moved down, it will move down out of the menu. However, no objects can be moved outside the boundaries of the main Openbox menu.

If a sub-menu is moved up or down, its contents move with it.

A menu cannot be moved into another menu, but a new menu can be created inside an existing menu, and items can be moved into it.

------------------------- **About menu.xml** --------------------------

At the heart of the Openbox static menu system is a configuration file, which is usually located at ~/.config/openbox/menu.xml

The menu.xml can be edited manually. The structure of each object within the menu is actually quite simple. Separators are only one line, items each consist of five lines, and menus may be quite complex, with items and sub-menus nested inside them.

Each line of menu.xml opens with a '<' pointy brace thing, and is closed by a '>'. Between the braces are words that describe their functions.

The framework of each line is:
   <Type Name Label ... >

   For example:
   <separator label="Internet"/>

   Or a menu (containing an item):
   <menu id="root-menu-123456" label="Browsers">
      <item label="Firefox">
         <action name="Execute">
            <execute>firefox</execute>
         </action>
      </item>
   </menu>

Most of the complexity of these is hidden by OBhelper, which takes care of the details for you.