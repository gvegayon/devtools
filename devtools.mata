*! vers 0.14.3 18mar2014
*! author: George G. Vega Yon

/* BULID SOURCE_DOC 
Creates source documentation from MATA files
*/

vers 12.0

mata:

/**
 * @brief Runs a stata command and captures the error
 * @param stcmd Stata command
 * @returns Integer _rc
 */
real scalar function dt_stata_cap(string scalar stcmd, | real scalar noisily) {
	
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
 * @brief Builds a help file from a MATA source file.
 * @param fns A List of mata files.
 * @param output Name of the resulting file
 * @param replace Whether to replace or not a hlp file.
 * @returns A nice help file showing source code.
 */
void dt_moxygen(
	string vector fns,
	string scalar output,
	| real scalar replace)
{
	
	/* Setup */
	real scalar i, j, fh_input, fh_output
	string scalar fn, line, funname, regexp_fun_head, rxp_oxy_brief, rxp_oxy_param, rxp_oxy_returns, rxp_oxy_auth, oxy
	string vector eltype_list, orgtype_list
	
	////////////////////////////////////////////////////////////////////////////////
	/* Building regexp for match functions headers */
	// mata
	eltype_list  = "transmorphic", "numeric", "real", "complex", "string", "pointer"
	orgtype_list = "matrix", "vector", "rowvector", "colvector", "scalar"
	
	/* Every single combination */
	regexp_fun_head = "^(void|"
	for(i=1;i<=length(eltype_list);i++)
		for(j=1;j<=length(orgtype_list);j++)
			regexp_fun_head = regexp_fun_head+eltype_list[i]+"[\s ]+"+orgtype_list[j]+"|"
	
	/* Single element */
	for(i=1;i<=length(eltype_list);i++)
		regexp_fun_head = regexp_fun_head+eltype_list[i]+"|"
	
	for(i=1;i<=length(orgtype_list);i++)
		if(i!=length(orgtype_list)) regexp_fun_head = regexp_fun_head+orgtype_list[i]+"|"
		else regexp_fun_head = regexp_fun_head+orgtype_list[i]+")[\s ]*(function)?[\s ]+([a-zA-Z0-9_]+)[(]"
		
	/* MATA oxygen */
	rxp_oxy_brief   = "^[\s ]*[*][\s ]*@brief[\s ]+(.*)"
	rxp_oxy_param   = "^[\s ]*[*][\s ]*@param[\s ]+([a-zA-Z0-9_]+)[\s ]*(.*)"	
	rxp_oxy_returns = "^[\s ]*[*][\s ]*@(returns?|results?)[\s ]*(.*)"
	rxp_oxy_auth    = "^[\s ]*[*][\s ]*@authors?[\s ]+(.*)"

	/*if (regexm("void build_source_doc(", regexp_fun_head))
		regexs(1), regexs(3)
	regexp_fun_head
	
	end*/
	
	////////////////////////////////////////////////////////////////////////////////
	if (replace == J(1,1,.)) replace = 1
	
	/* Checks if the file has to be replaced */
	if (!regexm(output, "[.]hlp$|[.]sthlp$")) output = output + ".sthlp"
	if (fileexists(output) & !replace)
	{
		errprintf("File -%s- already exists. Set -replace- option to 1.", output)
		exit(0)
	}
	
	/* Starting the hlp file */
	if (fileexists(output)) unlink(output)
	fh_output = fopen(output, "w", 1)
	
	/* Looping over files */
	for(i=1;i<=length(fns);i++)
	{
		/* Picking the ith filename */
		fn = fns[i]
		
		/* If it exists */
		if (fileexists(fn))
		{
			/* Opening the file */
			fh_input = fopen(fn, "r")
			
			/* Header of the file */
			fput(fh_output, "*! {smcl}")
			fput(fh_output, "*! {c TLC}{dup 78:{c -}}{c TRC}")
			fput(fh_output, "*! {c |} {bf:Beginning of file -"+fn+"-}{col 83}{c |}")
			fput(fh_output, "*! {c BLC}{dup 78:{c -}}{c BRC}")
			
			oxy = ""
			real scalar nparams, inOxygen, nauthors
			nparams  = 0
			nauthors = 0
			inOxygen = 0
			while((line = fget(fh_input)) != J(0,0,""))
			{
				/* MATAoxygen */
				if (regexm(line, "^[/][*]([*]|[!])(d?oxygen)?[\s ]*$") | inOxygen) {
				
					if (regexm(line, "^[\s ]*[*][/][\s ]*$"))
					{
						inOxygen = 0
						continue
					}
					
					/* Incrementing the number of oxygen lines */
					if (!inOxygen++) line = fget(fh_input)
					
					if (regexm(line, rxp_oxy_brief))
					{
						oxy = sprintf("\n*!{dup 78:{c -}}\n*!{col 4}{it:%s}",regexs(1))
						continue
					}
					if (regexm(line, rxp_oxy_auth))
					{
						if (!nauthors++) oxy = oxy+sprintf("\n*!{col 4}{bf:author(s):}")
						oxy = oxy+sprintf("\n*!{col 6}{it:%s}",regexs(1))
						continue
					}
					if (regexm(line, rxp_oxy_param))
					{
						if (!nparams++) oxy = oxy+sprintf("\n*!{col 4}{bf:parameters:}")
						oxy = oxy+sprintf("\n*!{col 6}{bf:%s}{col 20}%s",regexs(1),regexs(2))
						continue
					}
					if (regexm(line, rxp_oxy_returns))
					{
						oxy = oxy+sprintf("\n*!{col 4}{bf:%s:}\n*!{col 6}{it:%s}", regexs(1), regexs(2))
						continue
					}
				}
				
				/* Checking if it is a function header */
				if (regexm(line, regexp_fun_head)) 
				{
					funname = regexs(3)
					fput(fh_output, "{smcl}")
					fput(fh_output, "*! {marker "+funname+"}{bf:function -{it:"+funname+"}- in file -{it:"+fn+"}-}")
					fwrite(fh_output, "*! {back:{it:(previous page)}}")
					
					sprintf("{help %s##%s:%s}", regexr(output, "[.]sthlp$|[.]hlp$", ""), funname, funname)
					if (oxy!="") {
						fwrite(fh_output, oxy)
						oxy      = ""
						nparams  = 0
						nauthors = 0
						inOxygen = 0
					}
					fput(fh_output,sprintf("\n*!{dup 78:{c -}}{asis}"))
				}
				fput(fh_output, subinstr(line, char(9), "    "))
 
			}
						
			fclose(fh_input)
			
			/* Footer of the file */
			fput(fh_output, "*! {smcl}")
			fput(fh_output, "*! {c TLC}{dup 78:{c -}}{c TRC}")
			fput(fh_output, "*! {c |} {bf:End of file -"+fn+"-}{col 83}{c |}")
			fput(fh_output, "*! {c BLC}{dup 78:{c -}}{c BRC}")
			
			continue
		}
		
		/* If it does not exists */
		printf("File -%s- doesn't exists\n", fn)
		continue
				
	}
	
	fclose(fh_output)
}

/**
 * @brief Recursive highlighting for mata.
 * @param line String to highlight.
 * @returns A highlighted text (to use with display)
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

/*
txt = dt_highlight(`"build(1+1-less(h)- signa("hola") + 1 - insert("chao"))"')
txt
display(txt)
*/

/**
 * @brief Split a text into many lines
 * @param txt Text to analize (and split)
 * @param n Max line width
 * @param s Indenting for the next lines
 * @returns A text splitted into several lines.
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

// printf(dt_txt_split("Hola joe, como estais",8,2))

/**
 * @brief Builds a temp source help
 * @param fns A vector of file names to be parsed for Mata oxygen.
 * @param output Name of the output file.
 * @param replace Whether to replace the file or not.
 * @returns a hlp file (and a view of it).
 */
void function dt_moxygen_preview(| string vector fns, string scalar output, real scalar replace) {

	/* Filling emptyness */
	if (fns == J(1, 0, ""))  fns = dir(".","files","*.mata")
	if (output == J(1,1,"")) {
		output  = st_tempfilename()
		replace = 1
	}
	
	/* Building and viewing */
	dt_moxygen(fns, output, replace)
	
	stata("view "+output)
	
	return
	
}

/** 
 * @brief Install a stata module on the fly
 * @param fns A list of the files that should be installed
 * @returns 
 */
void function dt_install_on_the_fly(|string scalar pkgname, string scalar fns) {
	if (fns==J(1,1,"")) fns = dir(".","files","*.mlib")\dir(".","files","*.ado")\dir(".","files","*.sthlp")\dir(".","files","*.hlp")
	
	if (!length(fns)) return
	
	real scalar fh, i
	string scalar fn, toc, tmpdir

	if (!regexm(tmpdir = c("tmpdir"),"([/]|[\])$")) 
		tmpdir = tmpdir+"/"
	tmpdir
	if (pkgname == J(1,1,"")) pkgname = "__mytmppgk"
	
	/* Creating tmp toc */
	if (fileexists(tmpdir+"stata.toc")) unlink(tmpdir+"stata.toc")
	fh = fopen(tmpdir+"stata.toc","w")
	fput(fh, sprintf("v0\ndseveral packages\n")+"p "+pkgname)
	fclose(fh)
	
	/* Creating the pkg file */
	unlink(tmpdir+pkgname+".pkg")
	fh = fopen(tmpdir+pkgname+".pkg","w")
	
	fput(fh, "v 3")
	fput(fh, "d "+pkgname+" A package created by -devtools-.")
	fput(fh, "d Distribution-Date:"+sprintf("%tdCYND",date(c("current_date"),"DMY")))
	fput(fh, "d Author: "+c("username"))
	for(i=1;i<=length(fns);i++)
	{
	"copy "+fns[i]+" "+tmpdir+fns[i]
		if (dt_stata_cap("copy "+fns[i]+" "+tmpdir+fns[i]+", replace"))
		{
			fclose(fh)
			unlink(tmpdir+"stata.toc")
			_error("Can't continue: Error while copying the file "+fns[i])
		}
		
		fput(fh,"F "+fns[i])
	}
	
	fclose(fh)
	
	/* Installing the package */
	stata("cap ado unistall "+pkgname)
	
	real scalar cap
	if (cap=dt_stata_cap("net install "+pkgname+", from("+tmpdir+") force replace"))
	{
		unlink(tmpdir+"stata.toc")
		for(i=1;i<=length(fns);i++)
			unlink(tmpdir+fns[i])
		
		_error(cap,"An error has occurred while installing.")
	}

	/*
	/* Restarting dataset */
	if (c("N") | c("k")) 
	{
		if (c("os") != "Windows") 
		{ // MACOS/UNIX
			unlink("__pll"+parallelid+"_shell.sh")
			fh = fopen("__pll"+parallelid+"_shell.sh","w", 1)
			// fput(fh, "echo Stata instances PID:")
			
			// Writing file
			if (c("os") != "Unix") 
			{
				for(i=1;i<=nclusters;i++) 
					fput(fh, paralleldir+" -e do __pll"+parallelid+"_do"+strofreal(i)+".do &")
			}
			else 
			{
				for(i=1;i<=nclusters;i++) 
					fput(fh, paralleldir+" -b do __pll"+parallelid+"_do"+strofreal(i)+".do &")
			}
			
			fclose(fh)
			
			// stata("shell sh __pll"+parallelid+"shell.sh&")
			stata("winexec sh __pll"+parallelid+"_shell.sh")
		}
		else 
		{ // WINDOWS
			for(i=1;i<=nclusters;i++) 
			{
				// Lunching procces
				stata("winexec "+paralleldir+" /e /q do __pll"+parallelid+"_do"+strofreal(i)+".do ")
			}
		}
	}*/

	return
}

/**
 * @brief Looks up for a regex within a list of plain text files
 * @param regex Regex to lookup for
 * @param fns List of files to look in (default is to take all .do .ado .hlp .sthlp and .mata)
 * @returns Coordinates (line:file) where the regex was found 
 */
void dt_lookupregex(string scalar regex , | string colvector fns) {
	
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
			if (regexm(line, regex))
				printf("In line %g on file %s\n", j,fns[i])
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
				if (dt_stata_cap("ado uninstall "+tmppkg)) continue
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
	| string scalar newline
	)
{
	real scalar fh, buffsize
	string matrix EOF
	string scalar txt, txttmp
	string colvector fhv
	
	buffsize = 1024*1024
	
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
 * @brief Run a shell command and retrive its output
 * @param cmd Shell command to be runned
 */

string colvector function dt_shell(string scalar cmd) {
	string scalar tmp
	real scalar i, err
	string colvector out
	
	/* Running the comand */
	tmp = st_tempfilename()
	
	if ( (err = dt_stata_cap("shell "+cmd+" > "+tmp)) )
		_error(err, "Couldn't complete the operation")
	
	out = dt_read_txt(tmp)
	unlink(tmp)
	return(out)
}

/*
void dt_git_install(string scalar pkgname, string scalar usr, | string scalar which) {

	string colvector valid_repos
	valid_repos = ("github","bitbucket","googlecode")
	
	/* Checking which version */
	if (which == J(1,1,"")) which = "github"
	else if (!length(select(valid_repos,valid_repos:==which)))
		_error(1,"Invalid repo, try using -github-, -bitbucket- or -googlecode-")
			
	/* Check if git is */
	return
	
}*/
 
end

