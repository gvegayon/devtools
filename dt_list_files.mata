mata
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

