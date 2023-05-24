/*Vectors but they're actually matrices
	operator overload-less edition

	Every matrix can be imagined to represent a multiplication with the vector (1 1)
		For example: Matrix A * (1 1) = (-1 2) if Matrix A is the below:
		-1 0 0
		 0 2 0
		 0 0 1
		This is done to allow vector-like operator interactions without overloading, as vectors are essentially column matrices
		You just have to keep in mind x and y are actually the variables a and e

	Furthermore, the variables c and f indicate flat values that are added onto what is basically the origin point (0,0), to make a starting coordinate (c,f)
		We can use this to essentially define a starting point for our vector as shown here:
		-1 0 0
		 0 2 0
		 1 3 1
		Not only is the direction of this vector (-1 2) as said before, its starting point is now located at (x,y)=(1,3)


	Most of the procs here are just lazily edited versions from vector2d.dm to work with a matrix, so credit goes to qwertyquerty and Kmc2000 for their implementation.

Written by Bokkiewokkie
*/

//TODO: replace mentions of this with /matrix and shuffle the variables around to actually assign a through f instead of x and y
/matrix/vector/New(x=0,y=0,b=0,c=0,d=0,f=0)
	return ..(x,b,c,d,y,f)

//Set the X and Y length
/matrix/proc/_set(x,y,sanity=FALSE)
	a = x
	e = y
	if(sanity) //fall back to 0 if the inputs are invalid.
		if(!isnum_safe(x))
			a = 0
		if(!isnum_safe(y))
			e = 0

//Set the X and Y coordinates, same as the above otherwise
/matrix/proc/_set_positions(x,y,sanity=FALSE)
	c = x
	f = y
	if(sanity)
		if(!isnum_safe(x))
			c = 0
		if(!isnum_safe(y))
			f = 0

/matrix/proc/to_string()
	return "\[[a], [e]\]"

/matrix/proc/dot(var/matrix/V)
	return a * V.a + e * V.e

/matrix/proc/cross(var/matrix/V)
	return a * V.e - e * V.a

/matrix/proc/ln2()
	return dot(src)

/matrix/proc/ln()
	return sqrt(dot(src))

/matrix/proc/angle()
	return ATAN2(a, e)

/matrix/proc/normalize()
	return src / src.ln()


/matrix/proc/project(var/matrix/V)
	var/amt = src.dot(V) / V.ln2()
	a = amt * V.a
	e = amt * V.e
	return src

/matrix/proc/project_n(var/matrix/V)
	var/amt = src.dot(V)
	a = amt * V.a
	e = amt * V.e
	return src

/matrix/proc/reflect(axis)
	project(axis)
	src *= -2

/matrix/proc/reflect_n(axis)
	project_n(axis)
	src *= -2

/matrix/proc/perp()
	RETURN_TYPE(/matrix)
	return Turn(90)

/matrix/proc/copy(var/matrix/V)
	a = V.a
	e = V.e
	return src

/matrix/proc/clone()
	return new /matrix(a, e)

/matrix/proc/rotate(angle)
	return Turn(angle)

/matrix/proc/reverse()
	return Multiply(-1)

