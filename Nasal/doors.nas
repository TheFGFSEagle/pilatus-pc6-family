### doors 

var toggle_pilotdoor = func {
	door0 = aircraft.door.new ("/controls/doors/door0",3);
	if(getprop("/controls/doors/door0/position-norm") > 0) {
		door0.close();
	} else {
		door0.open();
	}
}

var toggle_copilotdoor = func {
	door1 = aircraft.door.new ("/controls/doors/door1",3);
	if(getprop("/controls/doors/door1/position-norm") > 0) {
		door1.close();
	} else {
		door1.open();
	}
}

var toggle_fswingdoor = func {
	door2 = aircraft.door.new ("/controls/doors/door2",3);
	if(getprop("/controls/doors/door2/position-norm") > 0) {
		door2.close();
	} else {
		door2.open();
	}
}

var toggle_rswingdoor = func {
	door3 = aircraft.door.new ("/controls/doors/door3",3);
	if(getprop("/controls/doors/door3/position-norm") > 0) {
		door3.close();
	} else {
		door3.open();
	}
}

var toggle_slidedoor = func {
	door4 = aircraft.door.new ("/controls/doors/door4",3);
	if(getprop("/controls/doors/door4/position-norm") > 0 ) {
		door4.close();
	} else {	
		door4.open();
	}
}

var toggle_rearhatch = func {
	door5 = aircraft.door.new ("/controls/doors/door5",3);
	if(getprop("/controls/doors/door5/position-norm") > 0) {
		door5.close();
	} else {
		door5.open();
	}
}