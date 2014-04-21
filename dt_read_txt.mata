mata
/**
 * @brief Reads a txt file (fast).
 * @param fn File name.
 * @param newline New line sep.
 * @returns A colvector of length = N of lines.
 */
string colvector function dt_read_txt(
	string scalar fn,
	| string scalar newline,
	real scalar buffsize
	)
{
	real scalar fh
	string matrix EOF
	string scalar txt, txttmp
	string colvector fhv
	
	if (buffsize == J(1,1,.)) buffsize = 1024*1024
	else if (buffsize > 1024*1024)
	{
		buffsize = 1024*1024
		display("Max allowed buffsize : 1024*1024")
	}
	
	if (newline == J(1,1,"")) newline = sprintf("\n")
	else newline = sprintf(newline)
	EOF = J(0,0,"")
	
	fh = fopen(fn,"r")
	txttmp = ""
	while((txt=fread(fh,buffsize)) != EOF) txttmp = txttmp+txt
	fclose(fh)
	
	fhv = tokens(txttmp,newline)'
	fhv = select(fhv, fhv:!=newline)
	
	return(fhv)
}
end
