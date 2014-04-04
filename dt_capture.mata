mata

	class dt_Capture {
		pointer(function) scalar func_ptr
		pointer matrix arg_ptrs
		pointer scalar rv_ptr
	}
	
	dt_capture = dt_Capture()

	/**
	 * @brief Capture mata functions errors
	 * @param func_pointer  pointer to a function (i.e., a pointer(function) scalar)
	 * @param arg_ptrs vector containing pointers to the intended arguments, or a zero-dimensional matrix if the function takes no arguments
	 * @param rv_ptr (optional) is a pointer to a pre-defined variable that will hold the return value of the function if it doesn't abort with error
	 * @returns smthg
	 */
	real scalar dt_capture(pointer(function) scalar func_ptr,
	                       pointer matrix arg_ptrs,
	                       | pointer scalar rv_ptr)
	{
		real scalar rc, i, nargs
		string scalar run_str, arg_template
		external class dt_Capture scalar dt_capture
		
		// It seems that any errors in pointer arguments get captured
		// by the Stata capture below. So, test them here.
		if (eltype(func_ptr) != "pointer") {
			exit(_error(3257, "1st arg should be a pointer to a function"))
		}
		if (orgtype(func_ptr) != "scalar") {
			exit(_error(3200, "1st arg should be a pointer scalar"))
		}
		if (args() == 3) {
			if (eltype(rv_ptr) != "pointer") {
				exit(_error(3257, "3rd arg should be a pointer"))
			}
			if (orgtype(rv_ptr) != "scalar") {
				exit(_error(3200, "3rd arg should be a pointer scalar"))
			}
		}
		
		// Check dimensions of arg_ptrs. It is allowed to be a vector, or
		// a zero-dimensional matrix if wanting to pass zero arguments.
		// I.e., J(0,0,.), J(0,1,.) J(123,0,.) are all allowed.
		if (rows(arg_ptrs) > 1 & cols(arg_ptrs) > 1) {
			exit(_error(3200, "2nd arg should be vector or zero-dim matrix"))
		}
		if (rows(arg_ptrs) != 0 & cols(arg_ptrs) !=0 & 
				eltype(arg_ptrs) != "pointer") {
			exit(_error(3257, "2nd arg should be a vector of pointers"))
		}
		
		dt_capture.func_ptr = func_ptr
		dt_capture.arg_ptrs = arg_ptrs
		
		if (args() == 3) {
			dt_capture.rv_ptr = rv_ptr
			run_str = "*(dt_capture.rv_ptr) = (*dt_capture.func_ptr)("
		}
		else {
			run_str = "(*dt_capture.func_ptr)("
		}
		arg_template = "*(dt_capture.arg_ptrs[%f])%s"
		
		nargs = length(arg_ptrs)
		for (i = 1; i <= nargs; i++) {
			run_str = run_str + sprintf(arg_template, i, i == nargs ? "" : ",") 
		}
		run_str = run_str + ")"
		
		stata("capture mata: " + run_str)
		stata("local rc = _rc")
		rc = strtoreal(st_local("rc"))
		
		// remove references to func_ptr, etc.
		dt_capture.func_ptr = NULL
		dt_capture.arg_ptrs = J(0,0,NULL)
		dt_capture.rv_ptr = NULL
		
		return(rc)
	}
	
	real scalar dt_method_capture(string scalar class_name,
	                              string scalar func_name, 
	                              pointer matrix arg_ptrs,
	                              | pointer scalar rv_ptr)
	{
		real scalar rc, i, nargs
		string scalar run_str, arg_template
		external class dt_Capture scalar dt_capture
		
		// It seems that any errors in pointer arguments get captured
		// by the Stata capture below. So, test them here.
		if (args() == 4) {
			if (eltype(rv_ptr) != "pointer") {
				exit(_error(3257, "4th arg should be a pointer"))
			}
			if (orgtype(rv_ptr) != "scalar") {
				exit(_error(3200, "4th arg should be a pointer scalar"))
			}
		}
		
		// Check dimensions of arg_ptrs. It is allowed to be a vector, or
		// a zero-dimensional matrix if wanting to pass zero arguments.
		// I.e., J(0,0,.), J(0,1,.) J(123,0,.) are all allowed.
		if (rows(arg_ptrs) > 1 & cols(arg_ptrs) > 1) {
			exit(_error(3200, "3rd arg should be vector or zero-dim matrix"))
		}
		if (rows(arg_ptrs) != 0 & cols(arg_ptrs) !=0 & 
				eltype(arg_ptrs) != "pointer") {
			exit(_error(3257, "3rd arg should be a vector of pointers"))
		}
		
		
		dt_capture.arg_ptrs = arg_ptrs
		
		if (args() == 4) {
			dt_capture.rv_ptr = rv_ptr
			run_str = "*(dt_capture.rv_ptr) = " + ///
			          class_name + "." + func_name + "("
		}
		else {
			run_str = class_name + "." + func_name + "("
		}
		arg_template = "*(dt_capture.arg_ptrs[%f])%s"
		
		nargs = length(arg_ptrs)
		for (i = 1; i <= nargs; i++) {
			run_str = run_str + sprintf(arg_template, i, i == nargs ? "" : ",") 
		}
		run_str = run_str + ")"
		
		stata("capture mata: " + run_str)
		stata("local rc = _rc")
		rc = strtoreal(st_local("rc"))
		
		// remove references
		dt_capture.arg_ptrs = J(0,0,NULL)
		dt_capture.rv_ptr = NULL
	
		return(rc)
	}
end
