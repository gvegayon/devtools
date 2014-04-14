mata

/**
* @brief Get dataset characteristics from Stata as associative array
* @param evarid (optional) scalar variable number, variable name, or "_dta"
* @returns associative array
* @demo
* stata("sysuse auto, clear")
* dtachars = dt_st_chars("_dta")
* asarray_keys(dtachars)
*/
transmorphic scalar dt_getchars(| transmorphic scalar evarid)
{
	transmorphic scalar A, B
	string vector evarlist, charnames
	string scalar evarname, charnamei, idtype
	real scalar i, j, nvar, evarnum, useall
	
	nvar = st_nvar()
	
	idtype = eltype(evarid)
	
	// Mata doesn't short-circuit logical tests
	useall = 1
	if (args() == 1) {
		useall = 0
		if (evarid == "") {
			useall == 1
		}
		else if (idtype == "real") {
			useall = missing(evarid)
		}
	}
	
	// if !useall check for errors and get chars for specified evarid
	if (!useall) {
		if (idtype == "real") {
			evarnum = round(evarid)
			if (evarid < 1 | evarid > nvar) {
				_error(3300, "argument out of range")
			}
			evarname = st_varname(evarnum)
		}
		else if (idtype == "string") {
			if (evarid == substr("_dta", 1, strlen(evarid))) {
				evarname = "_dta"
			}
			else {
				evarnum = _st_varindex(evarid, 1)
				if (evarnum == .) {
					_error(3500, "invalid Stata variable name")
				}
				evarname = st_varname(evarnum)
			}
		}
		else {
			_error(3255, "string or real required")
		}
		
		// It seems that charnames cannot contain binary.
		// If they can, using a local macro as below is not safe.
		stata("local _devtools_local : char " + evarname + "[]")
		
		charnames = tokens(st_local("_devtools_local"))
		
		// make associative array
		A = asarray_create()
		for (i = 1; i <= length(charnames); i++) {
			charnamei = charnames[i]
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
	
		// It seems that charnames cannot contain binary.
		// If they can, using a local macro as below is not safe.
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

/**
* @brief Set Stata dataset characteristics using associative array
* @param evarid scalar variable number, variable name, or "_dta". If setting all chars use "" or a missing value.
* @param chararry associative array from which to set characteristics
*/
void dt_setchars(transmorphic scalar evarid, transmorphic scalar chararray)
{
	transmorphic B
	string vector evarlist, charnames
	string scalar evarname, charnamei, idtype
	real scalar i, j, nvar, evarnum, useall
	
	nvar = st_nvar()
	
	idtype = eltype(evarid)
	
	// Mata doesn't short-circuit logical tests
	useall = 0
	if (evarid == "") {
		useall == 1
	}
	else if (idtype == "real") {
		useall = missing(evarid)
	}
	
	// if !useall check for errors and get chars for specified evarid
	if (!useall) {
		if (idtype == "real") {
			evarnum = round(evarid)
			if (evarid < 1 | evarid > nvar) {
				_error(3300, "argument out of range")
			}
			evarname = st_varname(evarnum)
		}
		else if (idtype == "string") {
			if (evarid == substr("_dta", 1, strlen(evarid))) {
				evarname = "_dta"
			}
			else {
				evarnum = _st_varindex(evarid, 1)
				if (evarnum == .) {
					_error(3500, "invalid Stata variable name")
				}
				evarname = st_varname(evarnum)
			}
		}
		else {
			_error(3255, "string or real required")
		}
		
		charnames = asarray_keys(chararray)
		
		for (i = 1; i <= length(charnames); i++) {
			charnamei = charnames[i]
			st_global(
				evarname + "[" + charnamei + "]",
				asarray(chararray, charnamei)
			)
		}
	}
	
	evarlist = J(1, nvar + 1, "")
	evarlist[1] = "_dta"
	for (i = 1; i <= nvar; i++) {
		evarlist[i + 1] = st_varname(i)
	}
	
	for (i = 1; i <= length(evarlist); i++) {
		evarname = evarlist[i]
		
		B = asarray(chararray, evarname)
		
		if (B == J(0,0,.)) continue
		
		charnames = asarray_keys(B)
		
		for (j = 1; j <= length(charnames); j++) {
			charnamei = charnames[j]
			st_global(
				evarname + "[" + charnamei + "]",
				asarray(B, charnamei)
			)
		}
	}
}

/**
* @brief Get value label from Stata as associative array, or set value label from associative array
* @param vlname scalar containing value label name
* @param vlarray (optional) associative array with integer keys and string contents
* @returns J(0,0,.) (void) if setting value vabel, associative array if retreiving value label
*/
transmorphic dt_vlasarray(string scalar vlname, | transmorphic scalar vlarray)
{
	transmorphic scalar A
	string vector text
	real vector values
	real scalar i
	
	// args() == 1 get associative array
	if (args() == 1) {
		A = asarray_create("real")
		
		if (st_vlexists(vlname)) {
			st_vlload(vlname, values, text)
			
			for (i = 1; i <= length(values); i++) {
				asarray(A, values[i], text[i])
			}
		}
		
		return(A)
	}
	
	// if args() == 2 set value label
	if (st_vlexists(vlname)) {
		st_vldrop(vlname)
	}
	
	values = asarray_keys(vlarray)
	
	text = J(rows(values), cols(values), "")
	
	for (i = 1; i <= length(values); i++) {
		text[i] = asarray(vlarray, floor(values[i]))
	}
	
	st_vlmodify(vlname, values, text)
}

end
