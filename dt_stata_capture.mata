mata
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
end
