capture mata: mata drop show()
capture mata: mata drop real_add()
capture mata: mata drop raise()
capture mata: mata drop weak_add()
capture mata: mata drop weak_show()

mata
	void show(real scalar a, string scalar b)
	{
		printf("a: %f    b: %s", a, b)
	}

	real real_add(real a, real b)
	{
		return(a + b)
	}
	
	void raise(real scalar num)
	{
		exit(error(num))
	}
	
	real weak_add(transmorphic a, transmorphic b)
	{
		real scalar sum, rc
		
		sum = .
		rc = capture(&real_add(), (&a, &b), &sum)
		if (rc) {
			return(.)
		}
		return(sum)
	}
	
	void weak_show(transmorphic a, transmorphic b)
	{
		real scalar rc
		rc = capture(&show(), (&a, &b))
		if (rc) {
			display("there was an error")
		}
	}

	rc = capture(&show(), (&0, &"blah"))
	rc
	//  0
	rc = capture(&show(), (&0, &1))
	rc
	// 3254
	
	c = .
	rc = capture(&real_add(), (&10, &"blah"), &c)
	(rc, c)
	// (3253, .)
	rc = capture(&real_add(), (&10, &101), &c)
	(rc, c)
	// (0, 111)

	rc = capture(&raise(), (&3200))
	rc
	// 3200
	
	rc = capture(&raise(), J(0,0,.))
	rc
	// 3001  --  J(0,0,.) used for "no args"
	  
	c = weak_add(0, 1)
	c
	// 1
	c = weak_add(0, "b")
	c
	// .
	  
	weak_show(0, "b")
	// output: [nothing]
	// output is silenced with capture()
	weak_show(0, 1)
	// output: "there was an error"
	// output produced outside of capture()
end
