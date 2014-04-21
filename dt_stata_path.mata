mata
/**
 * @brief Builds stata exe path
 * @returns Stata exe path
 * @demo
 * dt_stata_path()
 */
string scalar dt_stata_path(|real scalar xstata) {

	string scalar bit, flv
	string scalar statadir
	if (xstata==J(1,1,.)) xstata=0

	// Is it 64bits?
	if (c("osdtl") != "" | c("bit") == 64) bit = "-64"
	else bit = ""
	
	// Building fullpath name
	string scalar sxstata
	sxstata = (xstata ? "x" : "")

	if (c("os") == "Windows") { // WINDOWS
		if (c("MP")) flv = "MP"
		else if (c("SE")) flv = "SE"
		else if (c("flavor") == "Small") flv = "SM"
		else if (c("flavor") == "IC") flv = ""
	
		/* If the version is less than eleven */
		if (c("stata_version") < 11) statadir = c("sysdir_stata")+"w"+flv+"Stata.exe"
		else statadir = c("sysdir_stata")+"Stata"+flv+bit+".exe"

	}
	else if (regexm(c("os"), "^MacOS.*")) { // MACOS
	
		if (c("stata_version") < 11 & (c("osdtl") != "" | c("bit") == 64)) bit = "64"
		else bit = ""
	
		if (c("MP")) flv = "Stata"+bit+"MP" 
		else if (c("SE")) flv = "Stata"+bit+"SE"
		else if (c("flavor") == "Small") flv = "smStata"
		else if (c("flavor") == "IC") flv = "Stata"+bit
		
		statadir = c("sysdir_stata")+flv+".app/Contents/MacOS/"+sxstata+flv
	}
	else { // UNIX
		if (c("MP")) flv = "stata-mp" 
		else if (c("SE")) flv = "stata-se"
		else if (c("flavor") == "Small") flv = "stata-sm"
		else if (c("flavor") == "IC") flv = "stata"
	
		statadir = c("sysdir_stata")+sxstata+flv
	}

	if (!regexm(statadir, `"^["]"')) return(`"""'+statadir+`"""')
	else return( statadir )
}
end
