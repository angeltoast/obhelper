# OBhelper
A set of Bash shell scripts that try to do what obmenu used to do.

With OBmenu no longer in the Debian repos, this application tries to reproduce the functionality of OBmenu, though it is not intended to be an exact copy.

At this stage of development, it will be safer for you to download the scripts to a testing directory, with a copy of your menu.xml in the same location. Run it with  ./obh.sh

14th October 2021
   *  All functions are now working, though some are still buggy;
   *  obhelper uses the Yad suite of GTK dialogs for display, so please make
sure that you have Yad installed if you want to try OBhelper;
   *  There are 6 modules (scripts) - make sure you download them all;
   *  The application has not been widely tested, and may be incompatible with your system;
   *  There ARE bugs. If you are brave enough to try it, I would be happy for feedback;
   *  At present, OBhelper tries to read from an existing menu.xml at the same location as the scripts. A dummy menu.xml is included for testing, but of course you can use a copy of your own menu.xml;
   *  Any changes to data during testing are written to a temp.obh file for checking as the scripts run. It also uses another file 'display.obh' to hold the list as displayed in the listbox; both of these files should be deleted by OBhelper on exit, but may be left if the program exits abnormally;
   *  If you wish to use a different .xml file, pass the full address and name as an argument when starting OBhelper, eg: ./obh.sh "/absolute/path/to/your/menu.xml".