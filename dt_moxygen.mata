mata

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
	string scalar fn, line, funname
	string scalar regexp_fun_head, rxp_oxy_brief, rxp_oxy_param, rxp_oxy_returns, rxp_oxy_auth, oxy
	string scalar rxp_oxy_demo
	string vector eltype_list, orgtype_list
	
	string scalar tab
	tab = "([\s ]|"+sprintf("\t")+")*"
	
	////////////////////////////////////////////////////////////////////////////////
	/* Building regexp for match functions headers */
	// mata
	eltype_list  = "transmorphic", "numeric", "real", "complex", "string", "pointer"
	orgtype_list = "matrix", "vector", "rowvector", "colvector", "scalar"
	
	/* Every single combination */
	regexp_fun_head = "^"+tab+"(void|"
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
	rxp_oxy_brief   = "^"+tab+"[*][\s ]*@brief[\s ]+(.*)"
	rxp_oxy_param   = "^"+tab+"[*][\s ]*@param[\s ]+([a-zA-Z0-9_]+)[\s ]*(.*)"	
	rxp_oxy_returns = "^"+tab+"[*][\s ]*@(returns?|results?)[\s ]*(.*)"
	rxp_oxy_auth    = "^"+tab+"[*][\s ]*@authors?[\s ]+(.*)"
	rxp_oxy_demo = "^"+tab+"[*][\s ]*@demo(.*)"

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
			real scalar nparams, inOxygen, nauthors, inDemo, nDemos
			string scalar demostr, demoline
			nparams  = 0
			nauthors = 0
			inOxygen = 0
			inDemo   = 0
			demostr  = ""
			demoline = ""
			nDemos   = 0
			while((line = fget(fh_input)) != J(0,0,""))
			{
				/* MATAoxygen */
				if (regexm(line, "^"+tab+"[/][*]([*]|[!])(d?oxygen)?"+tab+"$") | inOxygen) {
				
					if (regexm(line, "^"+tab+"[*][/]"+tab+"$") & !inDemo)
					{
						inOxygen = 0
						continue
					}
					
					/* Incrementing the number of oxygen lines */
					if (!inOxygen++) line = fget(fh_input)
					
					if (regexm(line, rxp_oxy_brief))
					{
						oxy = sprintf("\n*!{dup 78:{c -}}\n*!{col 4}{it:%s}",regexs(2))
						continue
					}
					if (regexm(line, rxp_oxy_auth))
					{
						if (!nauthors++) oxy = oxy+sprintf("\n*!{col 4}{bf:author(s):}")
						oxy = oxy+sprintf("\n*!{col 6}{it:%s}",regexs(2))
						continue
					}
					if (regexm(line, rxp_oxy_param))
					{
						if (!nparams++) oxy = oxy+sprintf("\n*!{col 4}{bf:parameters:}")
						oxy = oxy+sprintf("\n*!{col 6}{bf:%s}{col 20}%s",regexs(2),regexs(3))
						continue
					}
					if (regexm(line, rxp_oxy_returns))
					{
						oxy = oxy+sprintf("\n*!{col 4}{bf:%s:}\n*!{col 6}{it:%s}", regexs(2), regexs(3))
						continue
					}
					if (regexm(line, rxp_oxy_demo) | inDemo)
					{
						string scalar democmd
						
						/* Checking if it ended with another oxy object */
						if ((regexm(line, rxp_oxy_demo) & inDemo) | regexm(line, "^"+tab+"@") | regexm(line, "^"+tab+"[*][/]"+tab+"$")) 
						{
							
							oxy      = oxy + sprintf("\n%s\n%s dt_enddem():({it:click to run})}\n",demostr,demoline)
							demostr  = ""
							demoline = ""
							inDemo   = 0
							
						}
									
						/* When it first enters */
						if (regexm(line, rxp_oxy_demo) & !inDemo)
						{
							demoline = "{matacmd dt_inidem();"
							demostr  = ""
							inDemo   = 1
							nDemos   = nDemos + 1
							
							oxy = oxy + sprintf("\n*!{col 4}{bf:Demo %g}", nDemos)
							continue
						}
						
						democmd = sprintf("%s", regexr(line,"^"+tab+"[*]",""))
						
						if (!regexm(democmd,"^"+tab+"/[*](.*)[*]/")) demoline = demoline+democmd+";"
						demostr  = demostr+sprintf("\n%s",democmd)
						continue
					}
				}
				/* Checking if it is a function header */
				if (regexm(line, regexp_fun_head)) 
				{
					funname = regexs(4)
					
					fput(fh_output, "{smcl}")
					fput(fh_output, "*! {marker "+funname+"}{bf:function -{it:"+funname+"}- in file -{it:"+fn+"}-}")
					fwrite(fh_output, "*! {back:{it:(previous page)}}")
					
//					printf("{help %s##%s:%s}", regexr(output, "[.]sthlp$|[.]hlp$", ""), funname, funname)
					if (oxy!="") {
						fwrite(fh_output, oxy)
						oxy      = ""
						nparams  = 0
						nauthors = 0
						inOxygen = 0
						nDemos   = 0
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

end
