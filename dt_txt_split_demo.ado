program define dt_txt_split_demo
	noi di " > this could be an extended demo for dt_txt_split"
	noi di `"mata: dt_txt_split("Hola joe, como estais",8,2)"'
	noi mata: dt_txt_split("Hola joe, como estais",8,2)
	noi di ""
	noi di " > etc ..."
end
