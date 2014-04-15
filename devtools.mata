*! vers 0.14.4 14apr2014
*! author: George G. Vega Yon

/* BULID SOURCE_DOC 
Creates source documentation from MATA files
*/

vers 11.0

mata:

/**
 * @brief Runs a stata command and captures the error
 * @param stcmd Stata command
 * @returns Integer _rc
 * @demo
 * /* This is a demo */
 * x = dt_stata_capture(`"di "halo""', 1)
 * x
 * /* Capturing error */
 * x = dt_stata_capture(`"di halo"', 1)
 * x
 */
real scalar function dt_stata_capture(string scalar stcmd, | real scalar noisily) {
	
	real scalar out
	
	/* Running the cmd */
	if (noisily == 1) stata("cap noi "+stcmd)
	else stata("cap "+stcmd)
	
	stata("local tmp=_rc")
	out = strtoreal(st_local("tmp"))
	st_local("tmp","")
	
	return(out)
}

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
 * @brief Run a shell command and retrive its output
 * @param cmd Shell command to be runned
 * @demo
 * /* Printing on the screen */
 * dt_shell("echo This works!")
 * @demo
 * /* Getting a list of files */
 * dt_shell("dir")
 */
string colvector function dt_shell(string scalar cmd) {
	string scalar tmp, prg
	real scalar i, err
	string colvector out
	
	/* Running the comand */
	tmp = dt_random_name()
	
	if ( (err = dt_stata_capture("shell "+cmd+" > "+tmp)) )
		_error(err, "Couldn't complete the operation")
	
	out = dt_read_txt(tmp)

	/* Removing cr (windows)*/
	real scalar nout
	if ((nout=length(out)) & c("os") == "Windows")
		for(i=1;i<=nout;i++)
			out[i] = regexr(out[i],sprintf("\r")+"+$","")

	unlink(tmp)
	return(out)
}

/**
 * @brief Erase using OS
 */
void function dt_erase_file(string scalar fns, | string scalar out, real scalar sh) {
	
	string scalar cmd, prg

	if (sh == 1) prg = "shell"
	else prg = "winexec"
	
	if (c("OS") == "Windows") cmd = "winexec erase /F "+fns
	else cmd = "winexec rm -f "+fns
	
	if (args()>1) out = cmd
	else stata(cmd)
	
	return
}

/**
 * @brief Copy using OS
 * @param fn1 Original file
 * @param fn2 New filename
 * @param out Optional, if specified then the cmd is not executed, rather it stores it at -out-
 * @returns A force copy from -fn1- to -fn2-
 */
void function dt_copy_file(string scalar fn1, string scalar fn2, | string scalar out, real scalar sh) {

	string scalar cmd, prg

	if (sh == 1) prg = "shell"
	else prg = "winexec"

	if (c("OS") == "Windows") cmd = prg+" copy /Y "+fn1+" "+fn2
	else cmd = prg+" cp -f "+fn1+" "+fn2
	
	if (args()>2) out = cmd
	else stata(cmd)
	
	return
}

 
/**
 * @brief Restarts stata
 * @param cmd Comand to execute after restarting stata
 * @returns Restarts stata, loads data and executes -cmd-
 */
void function dt_restart_stata(| string scalar cmd, real scalar ext) {

	real scalar fh
	real scalar isdta, ismata
	string scalar tmpcmd
	
	/* Checking if a dataset is loaded */
	if ( (isdta = c("N") | c("k")) )
	{
		string scalar tmpdta, dtaname
		dtaname = c("filename")
		tmpdta = dt_random_name()+".dta"
		stata("save "+tmpdta+", replace")
	}
	
	/* Checking if profile file already exists */
	real scalar isprofile
	isprofile = fileexists("profile.do")
	
	string scalar tmpprofile
	tmpprofile=dt_random_name()+".do"
	
	if (isprofile)
	{
		dt_copy_file("profile.do", tmpprofile)
		fh = fopen("profile.do","a")
	}
	else fh = fopen("profile.do","w")
	
	if (isdta) fput(fh, "use "+tmpdta+", clear")
	/* if (ismat) fput( */
	
	if (cmd != J(1,1,"")) fput(fh, cmd)
	
	/* Operations to occur right after loading the data*/
	if (isprofile)
	{	
		dt_copy_file(tmpprofile, "profile.do", tmpcmd)
		fput(fh, tmpcmd)
		fput(fh, "erase "+tmpprofile)
	}
	else 
	{
		dt_erase_file("profile.do", tmpcmd)
		fput(fh, tmpcmd)
	}
	
	/* Modifying data */
	if (isdta)
	{
		fput(fh, "erase "+tmpdta)
		fput(fh, "global S_FN ="+dtaname)
	}
	
	fclose(fh)
	
	if (ext==J(1,1,.)) ext=1
	
	string scalar statapath
	statapath = dt_stata_path(1)
	
	if (!dt_stata_capture("winexec "+statapath))
	{
		if (ext) stata("exit, clear")
	}
	else 
	{
		if (isprofile)
		{
			dt_copy_file(tmpprofile,"profile.do")
			unlink(tmpprofile)
		}
		else dt_erase_file("profile.do")
		if (isdta) unlink(tmpdta)
	}
	return
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
 * @brief Install a stata module on the fly
 * @param fns A list of the files that should be installed
 * @returns 
 */
void function dt_install_on_the_fly(
	|string scalar pkgname,
	string rowvector fns,
	string scalar pkgdir
) 
{
	/* Setting the folder */
	string scalar olddir
	olddir = c("pwd")
	if (args() < 3) pkgdir = c("pwd")

	if (dt_stata_capture("cd "+pkgdir))
		_error(1, "Couldn't find the -"+pkgdir+"- dir")
		
	/* If a pkg file exists, then use it! */
	if (fileexists(pkgname+".pkg")) {
		string colvector pkgf
		pkgf = dt_read_txt(pkgname+".pkg")
			real scalar i
		fns = J(1,0,"")
		for(i=1; i<= length(pkgf);i++)
			if (regexm(pkgf[i], "^(f|F)[\s ]+(.+)")) fns = fns, regexs(2)
	}

	/* Listing the files */
	if (fns==J(1,0,"")) fns = (dir(".","files","*.mlib")\dir(".","files","*.ado")\dir(".","files","*.sthlp")\dir(".","files","*.hlp"))'
		
	if (!length(fns)) return
	
	real scalar fh
	string scalar fn, toc, tmpdir

	if (!regexm(tmpdir = c("tmpdir"),"([/]|[\])$")) 
		tmpdir = tmpdir+"/"
	
	if (pkgname == J(1,1,"")) pkgname = "__mytmppgk"
	
	/* Creating tmp toc */
	if (fileexists(tmpdir+"stata.toc")) unlink(tmpdir+"stata.toc")
	fh = fopen(tmpdir+"stata.toc","w")
	fput(fh, sprintf("v0\ndseveral packages\n")+"p "+pkgname)
	fclose(fh)
	
	/* Creating the pkg file */
	unlink(tmpdir+pkgname+".pkg")
	if (fileexists(pkgname+".pkg")) /* if the package file exists, there is no need to build it!*/
	{
		dt_copy_file(pkgname+".pkg", tmpdir+pkgname+".pkg")
		for(i=1;i<=length(fns);i++)
		{
			// display("copy "+fns[i]+" "+tmpdir+fns[i])
			if (dt_stata_capture("copy "+fns[i]+" "+tmpdir+fns[i]+", replace"))
			{
				fclose(fh)
				unlink(tmpdir+"stata.toc")
				_error("Can't continue: Error while copying the file "+fns[i])
			}			
		}
	}
	else
	{
		fh = fopen(tmpdir+pkgname+".pkg","w")
		
		fput(fh, "v 3")
		fput(fh, "d "+pkgname+" A package compiled by -devtools-.")
		fput(fh, "d Distribution-Date:"+sprintf("%tdCYND",date(c("current_date"),"DMY")))
		fput(fh, "d Author: "+c("username"))
		for(i=1;i<=length(fns);i++)
		{
			// display("copy "+fns[i]+" "+tmpdir+fns[i])
			if (dt_stata_capture("copy "+fns[i]+" "+tmpdir+fns[i]+", replace"))
			{
				fclose(fh)
				unlink(tmpdir+"stata.toc")
				_error("Can't continue: Error while copying the file "+fns[i])
			}
			
			fput(fh,"F "+fns[i])
		}
		
		fclose(fh)
	}
	/* Installing the package */
	stata("cap ado unistall "+pkgname)
	
	real scalar cap
	if (cap=dt_stata_capture("net install "+pkgname+", from("+tmpdir+") force replace", 1))
	{
		unlink(tmpdir+"stata.toc")
		for(i=1;i<=length(fns);i++)
			unlink(tmpdir+fns[i])
		
		_error(cap,"An error has occurred while installing.")
	}

	stata("mata mata mlib index")
	
	stata("cap cd "+olddir)
	display("Package -"+pkgname+"- correctly installed")
	
	return
}

/**
 * @brief Equivalent to unix -less-
 * @param fname Name of the file to do less
 * @return void
 */
void function dt_less(string scalar fname)
{
	string colvector ftxt
	
	if (!fileexists(fname))
		_error(1, "The file -"+fname+"- does not exists.")
		
	ftxt = dt_read_txt(fname)
	
	real scalar i, n
	n =length(ftxt)
	for(i=1;i<=n;i++)
		printf("{text}"+ftxt[i]+"\n")
		
	return
}

/**
 * @brief Creates a .pkg file
 * @param pkgnb Name of the pakage and its description
 * @param fns List of files to be included in the package
 * @param replace whether to replace or not existing pkg files
 * @param pkgdir Dir where the package files lie
 * @demo
 * /* Creating an empty file */
 * dt_create_pkg("myexamplepkg",("a.ado","b.ado","a.sthlp","b.sthlp","lab.mlib"))
 * stata("view myexamplepkg.pkg")
 * dt_erase_file("myexamplepkg.pkg")
 */
void function dt_create_pkg(
	string scalar pkgnb , 
	| string rowvector fns,
	real scalar replace,
	string scalar auth,
	string scalar description,
	string scalar pkgdir
	)
{

	/* Parsing pkgnamed (name and description) */
	pkgnb = strtrim(pkgnb)
	
	string scalar pkgname, pkgbrief
	
	pkgname  = ""
	pkgbrief = ""
	if (regexm(pkgnb, "^([a-zA-Z0-9_]+) (.+)"))
	{
		pkgname  = regexs(1)
		pkgbrief = regexs(2)
	}

	/* Setting the folder */
	string scalar olddir
	olddir = c("pwd")
	if (args() < 6) pkgdir = c("pwd")

	if (dt_stata_capture("cd "+pkgdir))
		_error(1, "Couldn't find the -"+pkgdir+"- dir")

	/* Listing the files */
	if (fns==J(1,1,"")) fns = (dir(".","files","*.mlib")\dir(".","files","*.ado")\dir(".","files","*.sthlp")\dir(".","files","*.hlp"))'
	
	if (!length(fns)) return
	
	real scalar fh, i
	string scalar fn
	
	/* Checking the replace */
	if (replace ==J(1,1,.)) replace = 0
		
	/* Creating the pkg file */
	if (fileexists(pkgname+".pkg") & replace) unlink(pkgname+".pkg")
	else if (fileexists(pkgname+".pkg") & !replace)
		_error(1, "The file -"+pkgname+".pkg- already exists.")
	

	fh = fopen(pkgname+".pkg","w")
	
	fput(fh, "v 3")
	fput(fh, "d "+pkgname+ " " + (pkgbrief == ""? "A package compiled by -devtools-." : pkgbrief) )
	fput(fh, "d Distribution-Date:"+sprintf("%tdCYND",date(c("current_date"),"DMY")))
	fput(fh, "d Author: "+(auth == J(1,1,"") ? c("username") : auth) )
	for(i=1;i<=length(fns);i++)		
		fput(fh,"F "+fns[i])
	
	fclose(fh)

	return
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
void dt_uninstall_pkg(string scalar pkgname) {

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

/**
 * @brief Reads a txt file (fast).
 * @param fn File name.
 * @param newline New line sep.
 * @returns A colvector of length = N of lines.
 */
string colvector function dt_read_txt(
	string scalar fn,
	| string scalar newline,
	real scalar buffsize
	)
{
	real scalar fh
	string matrix EOF
	string scalar txt, txttmp
	string colvector fhv
	
	if (buffsize == J(1,1,.)) buffsize = 1024*1024
	else if (buffsize > 1024*1024)
	{
		buffsize = 1024*1024
		display("Max allowed buffsize : 1024*1024")
	}
	
	if (newline == J(1,1,"")) newline = sprintf("\n")
	else newline = sprintf(newline)
	EOF = J(0,0,"")
	
	fh = fopen(fn,"r")
	txttmp = ""
	while((txt=fread(fh,buffsize)) != EOF) txttmp = txttmp+txt
	fclose(fh)
	
	fhv = tokens(txttmp,newline)'
	fhv = select(fhv, fhv:!=newline)
	
	return(fhv)
}

/**
 * @brief Builds stata exe path
 * @returns Stata exe path
 * @demo
 * dt_stata_path()
 */
string scalar dt_stata_path(|real scalar xstata) {

	string scalar bit, flv
	string scalar statadir
	if (xstata==J(1,1,.)) xstata=0

	// Is it 64bits?
	if (c("osdtl") != "" | c("bit") == 64) bit = "-64"
	else bit = ""
	
	// Building fullpath name
	string scalar sxstata
	sxstata = (xstata ? "x" : "")

	if (c("os") == "Windows") { // WINDOWS
		if (c("MP")) flv = "MP"
		else if (c("SE")) flv = "SE"
		else if (c("flavor") == "Small") flv = "SM"
		else if (c("flavor") == "IC") flv = ""
	
		/* If the version is less than eleven */
		if (c("stata_version") < 11) statadir = c("sysdir_stata")+"w"+flv+"Stata.exe"
		else statadir = c("sysdir_stata")+"Stata"+flv+bit+".exe"

	}
	else if (regexm(c("os"), "^MacOS.*")) { // MACOS
	
		if (c("stata_version") < 11 & (c("osdtl") != "" | c("bit") == 64)) bit = "64"
		else bit = ""
	
		if (c("MP")) flv = "Stata"+bit+"MP" 
		else if (c("SE")) flv = "Stata"+bit+"SE"
		else if (c("flavor") == "Small") flv = "smStata"
		else if (c("flavor") == "IC") flv = "Stata"+bit
		
		statadir = c("sysdir_stata")+flv+".app/Contents/MacOS/"+sxstata+flv
	}
	else { // UNIX
		if (c("MP")) flv = "stata-mp" 
		else if (c("SE")) flv = "stata-se"
		else if (c("flavor") == "Small") flv = "stata-sm"
		else if (c("flavor") == "IC") flv = "stata"
	
		statadir = c("sysdir_stata")+sxstata+flv
	}

	if (!regexm(statadir, `"^["]"')) return(`"""'+statadir+`"""')
	else return( statadir )
}

/**
 * @brief Install a module from a git repo
 * @param pkgname Name of the package (repo)
 * @param usr Name of the repo owner
 * @param which Whether to install it from github, bitbucket or googlecode
 */
void dt_git_install(string scalar pkgname, string scalar usr, | string scalar which) {

	string colvector valid_repos, out
	string scalar uri
	valid_repos = ("github","bitbucket","googlecode")
	
	/* Checking which version */
	if (which == J(1,1,"")) which = "github"
	else if (!length(select(valid_repos,valid_repos:==which)))
		_error(1,"Invalid repo, try using -github-, -bitbucket- or -googlecode-")

	/* Checking git */
	out = dt_shell("git --version")
	if (!length(out)) 
		_error(1, "Git is not install in your OS.")
	else if (!regexm(out[1,1],"^git version"))
		_error(1, "Git is not install in your OS.")
			
	/* Check if git is */
	if (which=="github") uri = sprintf("https://github.com/%s/%s.git", usr, pkgname)

	out = dt_shell("git clone "+uri+" "+c("tmpdir")+"/"+pkgname)
	if (regexm(out[1,1],"^(e|E)rror"))
	{
		out
		_error(1,"Could connect to git repo")
	}

	dt_install_on_the_fly(pkgname,J(1,1,""),c("tmpdir")+"/"+pkgname)

	return
	
}
 
/**
 * @brief recursively list files
 * @param pattern File pattern such as '*mlib *ado'
 * @param regex (Unix systems only) 1 to specify that the pattern is a regex
 * @returns a list of files with their full path names
 * @demo
 * /* List of all the files */
 * dt_list_files()
 * @demo
 * /* List of ado files */
 * dt_list_files("*ado")
 */
string colvector function dt_list_files(|string scalar pattern, real scalar regex)
{
	string colvector files
	real scalar nfiles,i
	if (c("os")=="Windows")	
	{
		/* Retrieving the files from windows */
		files = dt_shell("dir /S /B "+pattern)	
	}
	else
	{
		/* Retrieving the files from Unix */
		if (strlen(pattern))
		{
			/* Preparing regex */
			if (args() < 2 | regex == 1)
			{
				pattern = subinstr(pattern,"*","",.)
				pattern = subinstr(pattern,".","\.",.)
				pattern = ".+("+subinstr(stritrim(strtrim(pattern))," ","|")+")$"
			}
			files = dt_shell("find . | grep -E '"+pattern+"'")
		}
		else files = dt_shell("find .")
		
		nfiles = length(files)
		
		/* Replacing dots */
		for(i=1;i<=nfiles;i++)
			files[i] = regexr(files[i],"^\.",c("pwd"))
		
	}
	return(files)
}

end

