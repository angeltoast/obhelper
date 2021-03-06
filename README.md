# OBhelper
A Bash script that tries to do what obmenu used to do.

*With OBmenu no longer in the Debian repos, this application tries to reproduce the functionality of OBmenu, though it is not intended to be an exact copy.*

**Currently released for testing only - not ready for deployment.**

*Unfortunately, due to illness, I have been unable to continue development. If anyone would like to clone the project and carry it forward, that would be nice. In the meantime, it will be safer for you to download the script to a testing directory, with a copy of your menu.xml in the same location. Run it with  ./obh.sh*

* obhelper uses the Yad suite of GTK dialogs for display, so please make sure that you have Yad installed;
*	Changes are not saved to menu.xml during a session. If you are happy with the changes at any stage, you can make them permanent by clicking 'Save'. If you leave the session without saving, all changes will be discarded;
* At present, OBhelper tries to read from an existing menu.xml at the same location as the scripts. A dummy menu.xml is included for testing, but of course you can use a copy of your own menu.xml;
* Any changes to data during testing are written to a temp.obh file for checking as the scripts run. It also uses another file 'display.obh' to hold the list as displayed in the listbox; both of these files should be deleted by OBhelper on exit, but may be left if the program exits abnormally;
* If you wish to use a different .xml file, pass the full address and name as an argument when starting OBhelper, eg: ./obh.sh "/absolute/path/to/your/menu.xml".
---------------------- Release notes ---------------------
24th October 2021 (v2021.1c)
	*	All scripts combined into one for easier use.
18th October 2021 (v2021.1b)
  *  All known bugs have been fixed, but there will be more;
  *  The application has not been widely tested, and may be incompatible with your system;
  *  There will be more bugs. If you are brave enough to try it, I would be happy for feedback;
