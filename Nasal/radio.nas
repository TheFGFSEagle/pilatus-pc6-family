#gestion de l'energie des radios

##
# Initialize the electrical system
##

var init_radio = func {
	print("Nasal Radio System Initialized"); 
}

setlistener("sim/signals/fdm-initialized", init_radio);

var adjust_volume0 = func{
	if(getprop("instrumentation/comm[0]/serviceable")){
		setprop("instrumentation/comm[0]/volume",getprop("instrumentation/comm[0]/volumeKnob"));
	}else{
		setprop("instrumentation/comm[0]/volume",0);
	}
}

var adjust_volume1 = func{
	if(getprop("instrumentation/comm[1]/serviceable")){
		setprop("instrumentation/comm[1]/volume",getprop("instrumentation/comm[1]/volumeKnob"));
	}else{
		setprop("instrumentation/comm[1]/volume",0);
	}
}

setlistener("instrumentation/comm[1]/serviceable",adjust_volume1);

var enable_comm0 = func{
	var volumeKnob = 0;
	var electrical = 0;
	if(getprop("/instrumentation/comm[0]/volumeKnob")!=nil){
		volumeKnob = getprop("/instrumentation/comm[0]/volumeKnob");
	}
	if(getprop("/systems/electrical/outputs/comm[0]")!=nil){
		electrical = getprop("/systems/electrical/outputs/comm[0]");
	}
	if(volumeKnob>0 and electrical>0){
		setprop("instrumentation/comm[0]/serviceable",1);
	}else{
		setprop("instrumentation/comm[0]/serviceable",0);
	}
}

setlistener("systems/electrical/outputs/comm[0]",enable_comm0);

var enable_comm1 = func{
	var volumeKnob = 0;
	var electrical = 0;
	if(getprop("/instrumentation/comm[1]/volumeKnob")!=nil){
		volumeKnob = getprop("/instrumentation/comm[1]/volumeKnob");
	}
	if(getprop("/systems/electrical/outputs/comm[1]")!=nil){
		electrical = getprop("/systems/electrical/outputs/comm[1]");
	}
	if(volumeKnob>0 and electrical>0){
		setprop("instrumentation/comm[1]/serviceable",1);
	}else{
		setprop("instrumentation/comm[1]/serviceable",0);
	}
}

setlistener("systems/electrical/outputs/comm[1]",enable_comm1);

var enable_transponder = func{
	var mode = 0;
	var electrical = 0;
	if(getprop("/instrumentation/transponder/mode")!=nil){
		mode = getprop("/instrumentation/transponder/mode");
	}
	if(getprop("/systems/electrical/outputs/transponder")!=nil){
		electrical = getprop("/systems/electrical/outputs/transponder");
	}
	
	if(mode>0 and electrical>0){
		setprop("/instrumentation/transponder/serviceable",1);
	}else{
		setprop("/instrumentation/transponder/serviceable",0);
	}
}

setlistener("/systems/electrical/outputs/transponder",enable_transponder);
setlistener("/instrumentation/transponder/mode",enable_transponder);

var assign_id_code = func{
	var id_code = getprop("/instrumentation/transponder/digit1") ~ getprop("/instrumentation/transponder/digit2") ~ getprop("/instrumentation/transponder/digit3") ~ getprop("/instrumentation/transponder/digit4");
	setprop("/instrumentation/transponder/id-code",id_code);
}

setlistener("/instrumentation/transponder/digit1",assign_id_code);
setlistener("/instrumentation/transponder/digit2",assign_id_code);
setlistener("/instrumentation/transponder/digit3",assign_id_code);
setlistener("/instrumentation/transponder/digit4",assign_id_code);