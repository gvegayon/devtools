mata
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

end
