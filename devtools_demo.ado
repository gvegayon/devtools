program define devtools_demo

	syntax [anything(name=which)] [, list]
	
	if ("`list'" != "") {
		noi di "available demos:"
		noi di "  dt_random_name"
		noi di "  dt_highlight"
		noi di "  dt_split_txt"
	}
	
	if ("`which'" != "") {
		mata: st_local("filepath", findfile("`which'_demo.ado"))
		
		capture noi `which'_demo
	}
	else if ("`list'" == "") {
		noi di "DEVTOOLS is a package containing functions"
		noi di "to help the Stata developer in his job, this"
		noi di "includes file management, utility tools such"
		noi di "as do-files parsing, installing/uninstalling"
		noi di "packages on the fly, misc. tools such as RNG"
		noi di "functions/Your mata capture function/installing"
		noi di "from git repo/restart stata/etc., tools for"
		noi di "documenting functions, etc."
		noi di ""
		noi di "For more info see -help devtools-, or to see"
		noi di "available demos do -demo devtools , list-."
	}
end

program define dt_random_name_demo
	noi di " > an optional argument sets length of output"
	noi di ": dt_random_name(5)"
	noi mata: dt_random_name(5)
	noi di ""
	noi di " > default length is 10"
	noi di ": dt_random_name()"
	noi mata: dt_random_name()
	noi di ""
	noi di " > optional argument should be real scalar"
	noi di `": dt_random_name("oops")"'
	noi capture noi mata: dt_random_name("oops")
end

program define dt_highlight_demo
	noi di " > dt_highlight() takes a string scalar and returns it highlighted"
	noi di `": dt_highlight("under") + "lined""'
	noi mata: dt_highlight("under") + "lined"
	noi di ""
	noi di " > the argument {ul}must{/ul} be a scalar"
	noi di `": dt_highlight("under" \ "lined")"'
	capture noi mata: dt_highlight("under" \ "lined")
end

