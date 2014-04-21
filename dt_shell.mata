mata
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
	while(fileexists(tmp = dt_random_name()))
		continue	
	
	if ( (err = dt_stata_capture("shell "+cmd+" > "+tmp)) )
		_error(err, "Couldn't complete the operation")
	
	out = dt_read_txt(tmp)

	/* Removing cr (windows)*/
	real scalar nout
	if ((nout=length(out)) & c("os") == "Windows")
		for(i=1;i<=nout;i++)
			out[i] = subinstr(out[i],sprintf("\r"),"")

	unlink(tmp)
	return(out)
}

/**
 * @brief Run a shell command and returns the exit status
 */
real scalar function dt_shell_return(string scalar cmd)
{
	string scalar cmdtxt
	if (c("os") == "Windows")
	{
		/* Writing tmp file which captures the error */
		string scalar batname
		real scalar fh
		while(fileexists(batname = tmpfilename()+".bat"))
			continue
		fh = fopen(batname,"w")
		fwrite(fh, sprintf("echo %%ERRORLEVEL%%"))
		fclose(fh)
		
		cmdtxt = "@echo off & "+cmd+" & "+batname
	}
	else cmdtxt = cmd+"; echo $?"

	return(strtoreal(dt_shell(cmdtxt)))
}
end
