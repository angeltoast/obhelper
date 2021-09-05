# obhelper
A Bash shell script that tries to do what obmenu used to do

With obmenu no longer in the Debian repos, this bash script will try to
include the functionality of obmenu, though it is not intended to be an
exact copy. obhelper uses the Yad suite of GTK dialogs for display, so
make sure that you have Yad installed.

Please note that obhelper is unfinished:
   *  Some functions have not yet been coded;
   *  The application has not been widely tested, and may be incompatible
      with your system;
   *  There WILL be bugs.
   *  At present, obhelper tries to read from an existing menu.xml at the
      default location of ~/.config/openbox/ but does not write to it.
      Any changes to data during testing are written to a temp.file for
      checking. If you wish to use a copy or dummy .xml file, pass the
      full address and name as an argument when starting obhelper, eg:
         ./obm.sh "/absolute/path/to/your/menu.xml"
      (the script file is called 'obm.sh' for speed of typing)