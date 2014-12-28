NAME
    parse.pl

DESCRIPTION
    Reads through input log files and stores data inside a complex data
    structure for trend analysis. The results of the trend analysis are
    printed out in a Dtrace like distribution graph. Each unique key (OS in
    the example below) is printed out by when they are seen in a format
    configured by the DATE_FORMAT variable.

      ============================================================
      Distribution By OS: ALL
      ============================================================
                  VALUE  --- DISTRIBUTION ------------------ COUNT
         Windows NT 5.0 |                                    432
         Windows NT 5.1 |@@@@@@@@@@@@                        7243
         Windows NT 5.2 |                                    94
         Windows NT 6.0 |@                                   1004
         Windows NT 6.1 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  19832
         Windows NT 6.2 |@@@                                 1759
         Windows NT 6.3 |@@@@@                               3128
      ============================================================
      Distribution By OS: Windows NT 5.2
      ============================================================
       VALUE  --- DISTRIBUTION ----------------------------- COUNT
      2014Q2 |@@@@@@                                         13
      2014Q3 |@@@@@@@                                        15
      2014Q4 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              66

USER TUNABLES
    Three options can be set by the user.

      $DEBUG         0 by default, any other value to enable
      $TERM_WIDTH    80 by default, 80x25 is standard cmd.exe size
      $DATE_FORMAT   YYYYQQ by default, valid values are listed below
      $RESULTS_FILE  Any text file name to save the trend analysis results

CONSTANTS/VARIABLES
    Valid date values:

      @VALID_DATE_FORMATS = ("YYYYMMDD", "YYYYMM", "YYYYQQ", "YYYY");

    Two variables are allocated for "global" usage:

      %clients       A structure of nested key => value mappings
      @uncatagorized Storage of potentially useful data not matched by any regex

SUBROUTINES
  parse_input_file()
    The parse_input_file subroutine expects one argument, a filename. It's
    role is to process the contents of that file and read usable data into
    the %clients hash data structure (a Hash of Hash of Hash of Hash). The
    result is four layers are stored to represent unique data.

    An example of one client's nested key value pairs as shown by
    Data::Dumper

      '192.168.1.100' => {
        'browser' => {
            'Firefox 27' => {
                '20141219' => 1
             }
         },
        'os' => {
            'Windows NT 6.1' => {
                '20141219' => 1
            }
         }
      },

  sort_trends()
    Sort trends searches for data in the %clients hash structure.

    It is called with three arguements:

      1. Title of the graph
      2. Field in the second level of the hash structure
      3. A text file for if debugging is enabled

    sort_trends('Distribution By OS', 'os', 'osHash.txt');

  print_trends()
    Print trends prints data in the hash it is provided both by field then
    by date inside each entry.

    It is called with two arguements:

      1. Title of the graph
      2. Reference to hash.

    print_trends("$title: ALL", \%workingHash);

  debug_dumparray() and debug_dump_hash()
    Prints reference hash or array into the file specified for later
    debugging efforts

    Both subroutines are called with two arguements:

      1. A text file for to put date into
      2. Reference to hash or array

    if ($DEBUG) { debug_dump_hash("DEBUG.txt", \%clients); }

    if ($DEBUG) { debug_dump_array("UNCATAGORIZED.txt", \@uncatagorized); }

