mata

/**
* @brief Get dataset characteristics from Stata as associative array
* @param evar (optional) scalar containing variable number, variable name, or "_dta"
* @returns associative array
*/
transmorphic dt_st_chars(| transmorphic scalar evar)
{
	transmorphic scalar A, B
	string vector evarlist, charnames
	string scalar evarname, charnamei, cmdstub
	real scalar i, j, nvar, evarnum
	
	nvar = st_nvar()
	
	// checking for errors and get chars for specified evar if args() == 1
	if (args() == 1) {
		if (eltype(evar) == "real") {
			evarnum = round(evar)
			if (evar < 1 | evar > nvar) {
				_error(3300, "argument out of range")
			}
			evarname = st_varname(evarnum)
		}
		else if (eltype(evar) == "string") {
			if (evar == substr("_dta", 1, strlen(evar))) {
				evarname = "_dta"
			}
			else {
				evarnum = _st_varindex(evar, 1)
				if (evarnum == .) {
					_error(3500, "invalid Stata variable name")
				}
				evarname = st_varname(evarnum)
			}
		}
		else {
			_error(3255, "string or real required")
		}
		
		stata("local _devtools_local : char " + evarname + "[]")
		
		charnames = tokens(st_local("_devtools_local"))
		
		// make associative array
		A = asarray_create()
		for (j = 1; j <= length(charnames); j++) {
			charnamei = charnames[j]
			asarray(A, charnamei, st_global(evarname + "[" + charnamei + "]"))
		}
		
		return(A)
	}
	
	evarlist = J(1, nvar + 1, "")
	evarlist[1] = "_dta"
	for (i = 1; i <= nvar; i++) {
		evarlist[i + 1] = st_varname(i)
	}
	
	// make associative array
	A = asarray_create()
	
	for (i = 1; i <= length(evarlist); i++) {
		evarname = evarlist[i]
	
		stata("local _devtools_local : char " + evarname + "[]")
		
		charnames = tokens(st_local("_devtools_local"))
		
		if (length(charnames) == 0) continue
		
		// make sub-array
		B = asarray_create()
		for (j = 1; j <= length(charnames); j++) {
			charnamei = charnames[j]
			asarray(B, charnamei, st_global(evarname + "[" + charnamei + "]"))
		}
		asarray(A, evarname, B)
	}
	
	return(A)
}

end
