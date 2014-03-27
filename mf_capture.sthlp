{smcl}
{* 26mar2014}{...}
{cmd:help mata capture()}
{hline}

{title:Title}

{p 4 4 2}
{bf:capture() {hline 2}} Capture function errors in Mata


{title:Syntax}

{p 8 20 2}
{it:real scalar}
{cmd:capture(}{it:func_ptr}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)}

{p 8 20 2}
{it:real scalar}
{cmd:method_capture(}{it:class_name}{cmd:,} {it:func_name}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)}

{p 4 8 2}
where

{p 8 12 2}
	{it:func_ptr} is a pointer to a function (i.e., a {it:pointer(function) scalar})

{p 8 12 2}
	{it:class_name} is a {it:string scalar}

	{it:func_name} is a {it:string scalar}
{p 8 12 2}

{p 8 12 2}
	{it:arg_ptrs} is a vector containing pointers to the intended arguments, or a zero-dimensional matrix if the function takes no arguments

{p 8 12 2}
	{it:rv_ptr} (optional) is a pointer to a pre-defined variable that will hold the return value of the function if it doesn't abort with error


{title:Description}

{pstd}
{cmd:capture()} runs the specified function with the specified arguments. If the
function aborts with error, {cmd:capture()} returns the error code. If the
function does not abort with error, {cmd:capture()} returns zero, and puts the
return value of the function in {it:rv_ptr}, if specified.

{pstd}
{cmd:method_capture()} does the same for a class method.


{title:Examples}

{pstd}
{cmd:capture()} is useful in the same situations as the Stata command 
{cmd:capture}. That is, when you want to verify that an error get raised, 
or when you want to handle an error yourself (or ignore it) rather than 
let the error halt your program.

{p 4 4 2}
{bf:Example 1}

{p 8 8 8}
Suppose you've made a function that tries to add any two inputs and return their
sum.

            function add(a, b)
            {
                return(a + b)
            }
	
{p 8 8 8}
Suppose your larger goal is to return the sum when possible or return the "." 
missing value otherwise. You could write a function like this


            function any_add(a, b) 
            {
                real scalar rc
                real matrix rv
                
                rc = capture(&add(), (&a, &b), &rv)
                if (rc) {
                	return(.)
                }
                return(rv)
            }
	
{p 8 8 8}
Your function then can be used like

            : any_add(1, 2)
              3
            
            : any_add(1, (0, 1))
              .
            
            : any_add(" foo ", " bar ")
               foo  bar 
            
            : any_add(" foo ", 2)
              .


{p 4 4 2}
{bf:Example 2}

{p 8 8 8}
Suppose you've made a function that takes a single argument which
is allowed to be a vector or zero-dimensional matrix, and suppose you want 
an error raised when that condition is not met. There is no built-in Mata
designation for "vector or zero-dimensional matrix", so the input will have 
to be checked with custom code.

            function thin(a)
            {
                if (rows(a) > 1 & cols(a) > 1) {
                    exit(_error(3200, "arg should be vector or zero-dim matrix"))
                }
            }
	
{p 8 8 8}
Since an error is being raised manually, you should probably write some tests
to check that the function raises the error you expect exactly when you expect 
it to. This can be done with {cmd:capture()} and the built-in {cmd:assert()}.
Some tests you might write:

            assert( capture(&thin(), &J(10, 1, 1)) == 0 )
            assert( capture(&thin(), &J(0, 0, 1)) == 0 )
            assert( capture(&thin(), &J(0, 10, 1)) == 0 )
            assert( capture(&thin(), &J(10, 2, 1)) == 3200 )
            assert( capture(&thin(), &J(10, 10, 1)) == 3200 )


{title:Conformability}

    {cmd:capture(}{it:func_ptr}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)}:
        {it:func_ptr}:  1 {it:x} 1
        {it:arg_ptrs}:  1 {it:x c}  or  {it:r x} 1  or  zero-dimensional
          {it:rv_ptr}:  1 {it:x} 1
          {it:result}:  1 {it:x} 1.

    {cmd:method_capture(}{it:class_name}{cmd:,} {it:func_name}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)}:
      {it:class_name}:  1 {it:x} 1
       {it:func_name}:  1 {it:x} 1
        {it:arg_ptrs}:  1 {it:x c}  or  {it:r x} 1  or  zero-dimensional
          {it:rv_ptr}:  1 {it:x} 1
          {it:result}:  1 {it:x} 1.


{title:Diagnostics}

{p 4 8 8}
{cmd:capture(}{it:func_ptr}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)} aborts
with error if {break}
{it:func_ptr} is not a pointer to a function,{break}
{it:arg_ptrs} is not a vector of pointers, or{break}
{it:rv_ptr} (if used) is not a pointer scalar.

{p 4 8 8}
{cmd:method_capture(}{it:class_name}{cmd:,} {it:func_name}{cmd:,} {it:arg_ptrs} [{cmd:,} {it:rv_ptr}]{cmd:)} aborts with error if{break}
{it:class_name} is not a string scalar,{break}
{it:func_name} is not a string scalar,{break}
{it:arg_ptrs} is not a vector of pointers, or{break}
{it:rv_ptr} (if used) is not a pointer scalar.

{p 4 4 8}
{cmd:method_capture()} will return 3000 if there is no class with name 
{it:class_name} or the class has no function with name {it:func_name}.

{pstd}
{cmd:method_capture()} will not work with classes defined within a function.


{title:Author}

{pstd}
James Fiedler{break}
{browse "mailto:jrfiedler@gmail.com":jrfiedler@gmail.com}

