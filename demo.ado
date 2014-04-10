program define demo
	syntax anything(name=which) [, list *]

	local cmd = word(`"`which'"', 1)
	local ext = substr(`"`which'"', strlen(`"`cmd'"') + 1, .)
	
	mata: st_local("filepath", findfile(`"`cmd'_demo.ado"'))
	
	if ("`filepath'" == "") {
		noi di as error `"-demo `cmd'- requires file `cmd'_demo.ado, which is not found"'
		exit 601
	}
	
	noi di ""
	if ("`list'" == "") {
		noi di "{txt}{hline 2} begin demo {hline}"
	}
	noi di ""
	capture noi `cmd'_demo `ext' , `list' `options'
	noi di ""
	if ("`list'" == "") {
		noi di "{txt}{hline 2} end demo {hline}"
	}
	noi di ""
	
	if (_rc) {
		noi di as error `"error while running `cmd'_demo"'
		exit _rc
	}
end
