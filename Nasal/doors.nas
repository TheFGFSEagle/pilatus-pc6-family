### doors 

door0 = aircraft.door.new ("/controls/doors/door0",3);
var toggle_pilotdoor = func {
	if(getprop("/controls/doors/door0/position-norm") > 0) {
		door0.close();
	} else {
		door0.open();
	}
}

door1 = aircraft.door.new ("/controls/doors/door1",3);
var toggle_copilotdoor = func {
	if(getprop("/controls/doors/door1/position-norm") > 0) {
		door1.close();
	} else {
		door1.open();
	}
}

door2 = aircraft.door.new ("/controls/doors/door2",3);
var toggle_fswingdoor = func {
	if(getprop("/controls/doors/door2/position-norm") > 0) {
		door2.close();
	} else {
		door2.open();
	}
}

door3 = aircraft.door.new ("/controls/doors/door3",3);
var toggle_rswingdoor = func {
	if(getprop("/controls/doors/door3/position-norm") > 0) {
		door3.close();
	} else {
		door3.open();
	}
}

door4 = aircraft.door.new ("/controls/doors/door4",3);
var toggle_slidedoor = func {
	if(getprop("/controls/doors/door4/position-norm") > 0 ) {
		door4.close();
	} else {	
		door4.open();
	}
}

door5 = aircraft.door.new ("/controls/doors/door5",3);
var toggle_rearhatch = func {
	if(getprop("/controls/doors/door5/position-norm") > 0) {
		door5.close();
	} else {
		door5.open();
	}
}
