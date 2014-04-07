program define devtools_demo

	syntax anything(name=which)
	
	noisily {
		di ""
		di "{txt}------------"
		di " begin demo"
		di "------------"
		capture noi demo_`which'
		di "{txt}------------"
		di "  end demo"
		di "------------"
		di ""
	}
	
end

program define demo_dt_random_name
	noisily {
		di " > an optional argument sets length of output"
		di ": dt_random_name(5)"
		mata: dt_random_name(5)
		di ""
		di " > default length is 10"
		di ": dt_random_name()"
		mata: dt_random_name()
		di ""
		di " > optional argument should be real scalar"
		di `": dt_random_name("oops")"'
		capture noi mata: dt_random_name("oops")
	}
end
