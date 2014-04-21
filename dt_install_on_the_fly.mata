mata
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
	olddir = pwd()
	if (args() < 3) pkgdir = pwd()

	if (dt_stata_capture("cd "+pkgdir))
		_error(1, "Couldn't find the -"+pkgdir+"- dir")
		
	/* If a pkg file exists, then use it! */
	if (fileexists(pkgname+".pkg")) 
	{
		string colvector pkgf
		pkgf = dt_read_txt(pkgname+".pkg")
		real scalar i
		fns = J(1,0,"")
		for(i=1; i<= length(pkgf);i++)
			if (regexm(pkgf[i], "^(f|F)[\s ]+(.+)")) fns = fns, regexs(2)
	}

	/* Listing the files */
	if (fns==J(1,0,"")) fns = (dir(".","files","*.mlib")\dir(".","files","*.ado")\dir(".","files","*.sthlp")\dir(".","files","*.hlp"))'
		
	if (!length(fns))
		_error(1,"No files found to be installed at -"+pkgdir+"-")
	
	real scalar fh
	string scalar fn, toc, tmpdir
	
	if (pkgname == J(1,1,"")) pkgname = "__mytmppgk"
	
	/* Creating tmp toc */
	real scalar tocexists, exitstatus
	string scalar tmptocname
	if (fileexists("stata.toc"))
	{
		tocexists = 1
		while (fileexists(tmptocname=dt_random_name())) 
			continue
		exitstatus = dt_rename_file("stata.toc", tmptocname)
		if (exitstatus)
		{
			stata("cap cd "+olddir)
			_error(1, "Couldn't rename the file -stata.toc-.")
		}
	}
	else tocexists = 0
	
	fh = fopen(tmpdir+"stata.toc","w")
	fput(fh, sprintf("v0\ndseveral packages\n")+"p "+pkgname)
	fclose(fh)
	
	/* Creating the pkg file */
	real scalar cap, pkgexists
	if (!(pkgexists = fileexists(pkgname+".pkg")))
	{
		fh = fopen(pkgname+".pkg","w")
		
		fput(fh, "v 3")
		fput(fh, "d "+pkgname+" A package compiled by -devtools-.")
		fput(fh, "d Distribution-Date:"+sprintf("%tdCYND",date(c("current_date"),"DMY")))
		fput(fh, "d Author: "+c("username"))
		for(i=1;i<=length(fns);i++)			
			fput(fh,"F "+fns[i])
		
		fclose(fh)
	}
	/* Installing the package */
	// stata("cap ado unistall "+pkgname)
	
	if (cap=dt_stata_capture("net install "+pkgname+", from("+pkgdir+") force replace", 1))
	{
		unlink("stata.toc")
		if (tocexists) exitstatus = dt_rename_file(tmptocname,"stata.toc")
		if (!pkgexists) unlink(pkgname+".pkg")
		stata("cap cd "+olddir)
		_error(cap,"An error has occurred while installing.")
	}

	stata("cap mata mata mlib index")
	
	stata("cap cd "+olddir)
	
	/* Clean up */
	unlink("stata.toc")
	if (tocexists) exitstatus = dt_rename_file(tmptocname,"stata.toc")
	if (!pkgexists) unlink(pkgname+".pkg")
	
	return
}

end
