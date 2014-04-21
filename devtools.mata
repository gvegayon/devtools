*! vers 0.14.4 14apr2014
*! author: George G. Vega Yon

/* BULID SOURCE_DOC 
Creates source documentation from MATA files
*/

vers 11.0

mata:

/**
 * @brief Random name generation
 * @param n Char length
 * @demo
 * /* Random name of length 10 */
 * dt_random_name()
 * /* Random name of length 5 */
 * dt_random_name(5)
 */
string scalar function dt_random_name(| real scalar n) {
	
	string scalar output
	string vector letters
	real scalar i
	
	if (n == J(1,1,.)) n = 10
	n = n - 1 
	
	letters = (tokens(c("alpha")), strofreal(0..9))'
	output = "_"
	
	for(i=1;i<=n;i++) output=output+jumble(letters)[1]
	
	return(output)
}

/**
 * @brief Renames a file using OS
 */
real scalar function dt_rename_file(string scalar fn1, string scalar fn2)
{
	/* Checking that both files exists */
	if (!fileexists(fn1)) _error(1, sprintf("File -%s- does not exitst.",fn1))
	if (fileexists(fn2)) _error(1, sprintf("File -%s- already exitst.",fn2))
	
	if (c("os") == "Windows") return(dt_shell_return("rename "+fn1+" "+fn2))
	else return(dt_shell_return("mv -f "+fn1+" "+fn2))
}

/**
 * @brief Erase using OS
 */
real scalar function dt_erase_file(string scalar fns, | string scalar out) {
	
	string scalar cmd
	
	if (c("os") == "Windows")
	{
		fns = subinstr(fns, "/","\",.)
		cmd = " erase /F "+fns
	}
	else cmd = " rm -f "+fns
	
	if (args()>1)
	{
		out = cmd
		return(0)
	}
	else
	{
		return(dt_shell_return(cmd))
	}
}

/**
 * @brief Dir recursively using OS
 */
real scalar function dt_erase_dir(string scalar xdir, | string scalar out) {
	
	string scalar cmd
	
	if (c("os") == "Windows")
	{
		xdir = subinstr(xdir, "/", "\", .)
		cmd = "rmdir /S "+xdir
	}
	else cmd = "rm -f -r "+xdir
	
	if (args()>1)
	{
		out = cmd
		return(0)
	}
	else
	{
		return(dt_shell_return(cmd))
	}
	
}

/**
 * @brief Copy using OS
 * @param fn1 Original file
 * @param fn2 New filename
 * @param out Optional, if specified then the cmd is not executed, rather it stores it at -out-
 * @returns A force copy from -fn1- to -fn2-
 */
real scalar function dt_copy_file(string scalar fn1, string scalar fn2, | string scalar out) {

	string scalar cmd
	
	if (c("os") == "Windows")
	{
		/* Avoiding modifier errors */
		fn1 = subinstr(fn1, "/", "\", .)
		fn2 = subinstr(fn2, "/", "\", .)
		cmd = "copy /Y "+fn1+" "+fn2
	}
	else cmd = " cp -f "+fn1+" "+fn2
	
	cmd
	if (args()>2)
	{
		out = cmd
		return(0)
	}
	else 
	{
		return(dt_shell_return(cmd))
	}
}

/**
 * @brief Begins a demo
 */
void function dt_inidem(|string scalar demoname, real scalar preserve) {
	if (args() < 2 | preserve == 1) stata("preserve")
	display("{txt}{hline 2} begin demo {hline}")
	display("")
	return
}

/**
 * @brief Ends a demo
 */
void function dt_enddem(| real scalar preserve) {
	if (args() < 1 | preserve == 1) stata("restore")
	display("")
	display("{txt}{hline 2} end demo {hline}")
	return
}

/**
 * @brief Recursive highlighting for mata.
 * @param line String to highlight.
 * @returns A highlighted text (to use with display)
 * @demo
 * txt = dt_highlight(`"build(1+1-less(h)- signa("hola") + 1 - insert("chao"))"')
 * txt
 * display(txt)
 */
string scalar dt_highlight(string scalar line) {
	string scalar frac, newline
	real scalar test
	
	string scalar regexfun, regexstr
	regexfun = "^(.+[+]|.+[*]|.+-|.+/|)?[\s ]*([a-zA-Z0-9_]+)([(].+)"
	regexstr = `"^(.+)?(["][a-zA-Z0-9_]+["])(.+)"'
	
	test = 1
	newline =""
	/* Parsing functions */
	while (test)
	{
		if (regexm(line, regexfun))
		{
			frac = regexs(2)
			newline = sprintf("{bf:%s}",frac) + regexs(3)+newline
			line = subinstr(line, frac+regexs(3), "", 1)
		}
		else test = 0
	}

	test = 1
	line = line+newline
	newline =""
	/* Parsing strings */
	while (test)
	{
		if (regexm(line, regexstr))
		{
			frac = regexs(2)
			newline = sprintf("{it:%s}",frac)+ regexs(3) + newline 
			line = subinstr(line, frac+regexs(3), "", 1)
		}
		else test = 0
		
	}
		
	return("{text:"+line+newline+"}")
}

/**
 * @brief Split a text into many lines
 * @param txt Text to analize (and split)
 * @param n Max line width
 * @param s Indenting for the next lines
 * @returns A text splitted into several lines.
 * @demo
 * printf(dt_txt_split("There was this little fella who once jumped into the water...\n", 10, 2))
 * @demo
 * printf(dt_txt_split("There was this little fella who once jumped into the water...\n", 15, 4))
 */
string scalar function dt_txt_split(string scalar txt, | real scalar n, real scalar indent) {

	string scalar newtxt, sindent
	real scalar curn, i

	if (n==J(1,1,.))
	{
		n = 80
		indent = 0
	}
	
	/* Creating the lines indenting */
	sindent = ""
	for(i=0;i<indent;i++) sindent = sindent + " "
	
	i = 0
	if ((curn = strlen(txt)) > n)
		while ((curn=strlen(txt)) > 0) {
			
			if (!i++) newtxt = substr(txt,1,n)
			else newtxt = newtxt + sprintf("\n"+sindent) + substr(txt,1,n)
			txt = substr(txt,n+1)
			
		}
		
	return(newtxt)
}


/**
 * @brief Looks up for a regex within a list of plain text files
 * @param regex Regex to lookup for
 * @param fixed Whether to interpret the regex arg as a regex or not (1: Not, 0: Yes)
 * @param fns List of files to look in (default is to take all .do .ado .hlp .sthlp and .mata)
 * @returns Coordinates (line:file) where the regex was found 
 */
void dt_lookuptxt(string scalar pattern , | real scalar fixed, string colvector fns) {
	
	if (!length(fns)) fns = dir(".","files","*.do")\dir(".","files","*.ado")\dir(".","files","*.mata")
	
	if (!length(fns)) return
	
	real scalar fh, nfs, i ,j
	string scalar line
	
	nfs = length(fns)
		
	for(i=1;i<=nfs;i++)
	{
		// printf("Revisando archivo %s\n",fns[i])
		fh = fopen(fns[i],"r")
		j=0
		while((line=fget(fh)) != J(0,0,"")) {
			j = j+1

			if (fixed)
			{
				if (strmatch(line,"*"+pattern+"*"))
					printf("In line %g on file %s\n", j, fns[i])
			}
			else
			{
				if (regexm(line, pattern))
					printf("In line %g on file %s\n", j,fns[i])
			}
		}

		fclose(fh)
	}

}

/**
 * @brief Uninstall all versions of a certain package
 * @param pkgname Name of the package
 * @returns Nothing
 */
void function dt_uninstall_pkg(string scalar pkgname) {

	string scalar pkgs
	string scalar logname, regex, line, tmppkg
	real scalar fh, counter

	counter = 0
	logname = st_tempfilename()
	while (counter >= 0)
	{
		/* Listing files */
		stata("log using "+logname+", replace text")
		stata("ado dir "+pkgname)
		stata("log close")

		/* Looking for pkgs and removing them */
		fh = fopen(logname, "r")

		regex = "^[ ]*([[][0-9]+[]]) package "+pkgname
		counter = 0
		while((line=fget(fh)) != J(0,0,"")) 
		{
			/* If the package matched, then remove it */
			if (regexm(line, regex)) 
			{
				tmppkg = regexs(1)
				display("Will remove the package "+tmppkg+" ("+pkgname+")")
				if (dt_stata_capture("ado uninstall "+tmppkg)) continue
				else counter = counter + 1
			}
		}

		fclose(fh)
		unlink(logname)
		
		if (counter == 0) counter = -1
		else counter = 0
	}
	return
}
end
