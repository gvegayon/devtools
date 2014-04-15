# devtools
Tools for the Stata developer

## Description
A colection of functions for the stata developer. A list of the current
available functions is:

* `dt_stata_capture()` A wrapper of `stata()`.
* `dt_random_name()` RN(ame)G algorithm based on current datetime.
* `dt_shell()` A wrapper of `shell` which retrives OS cmdline output.
* `dt_erase_file()` Deleting files through the OS cmdline.
* `dt_copy_file()` Copying files through the OS cmdline.
* `dt_restart_stata()` Restart stata.
* `dt_moxygen()` Doxygen for MATA! (and soon for stata).
* `dt_highlight()` Highlight MATA syntax with SMCL.
* `dt_txt_split()` Fixing a paragraph width.
* `dt_moxygen_preview()` Preview a hlp file of MATA source with Doxygen.
* `dt_install_on_the_fly()` Install a package on the fly.
* `dt_lookuptxt()` Search text or regex within plaintext files.
* `dt_uninstall_pkg()` Uninstall a package.
* `dt_read_txt()` Fast plain text importing into MATA.
* `dt_stata_path()` Retriving stata's exe path.
* `dt_capture()` Capturing a MATA function.
* `dt_getchars()` Retrieving Stata characteristics as associative arrray.
* `dt_setchars()` Set Stata characteristics from associative array.
* `dt_vlasarray()` Stata value label <-> Mata associative array.
* `dt_git_install()` Install a stata pkg from a git repo.
* `dt_list_files()` List files recursively.
* `dt_create_pkg()` Create a pkg file.
* `dt_less()` Stata equivalent for UNIX less.

Plus a set of functions to build and call modules' (packages') demos!

## Authors
George Vega (g dot vegayon at gmail dot com)

James Fiedler (jrfiedler at gmail dot com)

