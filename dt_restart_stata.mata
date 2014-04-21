mata
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

end
