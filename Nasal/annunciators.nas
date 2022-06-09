#gestion des annunciators

##
# Initialize the annunciator system
##

var init_annunciator = func {
	print("Nasal Annunciator System Initialized"); 
	settimer(update_annunciators,0);
}

setlistener("sim/signals/fdm-initialized", init_annunciator);

#test des annunciators
var annunciators_test = func(){
	if(getprop("/instrumentation/annunciators/general/serviceable")){
		setprop("/sim/alarms/caution-warning",1);
		setprop("/sim/alarms/warning-warning",1);
		
		setprop("/sim/alarms/annunciator.light_1_1",1);
		setprop("/sim/alarms/annunciator.light_2_1",1);
		setprop("/sim/alarms/annunciator.light_3_1",1);
		setprop("/sim/alarms/annunciator.light_4_1",1);
		setprop("/sim/alarms/annunciator.light_1_2",1);
		setprop("/sim/alarms/annunciator.light_2_2",1);
		setprop("/sim/alarms/annunciator.light_3_2",1);
		setprop("/sim/alarms/annunciator.light_4_2",1);
		setprop("/sim/alarms/annunciator.light_1_3",1);
		setprop("/sim/alarms/annunciator.light_2_3",1);
		setprop("/sim/alarms/annunciator.light_3_3",1);
		setprop("/sim/alarms/annunciator.light_4_3",1);
		setprop("/sim/alarms/annunciator.light_1_4",1);
		setprop("/sim/alarms/annunciator.light_2_4",1);
		setprop("/sim/alarms/annunciator.light_3_4",1);
		setprop("/sim/alarms/annunciator.light_4_4",1);
		setprop("/sim/alarms/annunciator.light_1_5",1);
		setprop("/sim/alarms/annunciator.light_2_5",1);
		setprop("/sim/alarms/annunciator.light_3_5",1);
		setprop("/sim/alarms/annunciator.light_4_5",1);
		
		setprop("/sim/alarms/annunciator.test",1);

		settimer(annunciators_reset,5);
	}
}

var annunciators_reset = func(){
	setprop("/sim/alarms/caution-warning",0);
	setprop("/sim/alarms/warning-warning",0);
	
	setprop("/sim/alarms/annunciator.light_1_1",0);
	setprop("/sim/alarms/annunciator.light_2_1",0);
	setprop("/sim/alarms/annunciator.light_3_1",0);
	setprop("/sim/alarms/annunciator.light_4_1",0);
	setprop("/sim/alarms/annunciator.light_1_2",0);
	setprop("/sim/alarms/annunciator.light_2_2",0);
	setprop("/sim/alarms/annunciator.light_3_2",0);
	setprop("/sim/alarms/annunciator.light_4_2",0);
	setprop("/sim/alarms/annunciator.light_1_3",0);
	setprop("/sim/alarms/annunciator.light_2_3",0);
	setprop("/sim/alarms/annunciator.light_3_3",0);
	setprop("/sim/alarms/annunciator.light_4_3",0);
	setprop("/sim/alarms/annunciator.light_1_4",0);
	setprop("/sim/alarms/annunciator.light_2_4",0);
	setprop("/sim/alarms/annunciator.light_3_4",0);
	setprop("/sim/alarms/annunciator.light_4_4",0);
	setprop("/sim/alarms/annunciator.light_1_5",0);
	setprop("/sim/alarms/annunciator.light_2_5",0);
	setprop("/sim/alarms/annunciator.light_3_5",0);
	setprop("/sim/alarms/annunciator.light_4_5",0);
	
	setprop("/sim/alarms/annunciator.test",0);
}

var update_annunciators=func{
	if(getprop("/instrumentation/annunciators/general/serviceable")){
		if(!getprop("/sim/alarms/annunciator.test")){
			#battery bus check
			var batterie_bus_serviceable = getprop("/systems/electrical/battery/serviceable");
			if(!batterie_bus_serviceable){
				setprop("/sim/alarms/annunciator.light_2_1",1);
			}else{
				setprop("/sim/alarms/annunciator.light_2_1",0);
			}
			
			#alternator bus check
			var alternator_bus_serviceable = getprop("/systems/electrical/alternator/serviceable");
			if(!alternator_bus_serviceable){
				setprop("/sim/alarms/annunciator.light_3_1",1);
				#setprop("/sim/alarms/warning-warning",1);
			}else{
				setprop("/sim/alarms/annunciator.light_3_1",0);
			}
			
			#var starter = getprop("/instrumentation/starter/serviceable");
			#if(starter){
			#	setprop("/sim/alarms/annunciator.light_1_5",1);
			#}else{
			#	setprop("/sim/alarms/annunciator.light_1_5",0);
			#}
		
			#var ignition = getprop("/instrumentation/ignition/serviceable");
			#if(ignition){
			#	setprop("/sim/alarms/annunciator.light_2_5",1);
			#}else{
			#	setprop("/sim/alarms/annunciator.light_2_5",0);
			#}

			var fuel_pump = getprop("/instrumentation/aux_fuel_pump/serviceable");
			if(fuel_pump){
				setprop("/sim/alarms/annunciator.light_1_4",1);
			}else{
				setprop("/sim/alarms/annunciator.light_1_4",0);
			}
			
			var fuel_press = getprop("/engines/pt6a/fuel_press");
			if(fuel_press<0.5){
				setprop("/sim/alarms/annunciator.light_1_3",1);
			}else{
				setprop("/sim/alarms/annunciator.light_1_3",0);
			}
			
			var battery_click = getprop("/controls/switches/battery-click");
			var generator_click = getprop("/controls/switches/generator-click");
			if(!generator_click){
				setprop("/sim/alarms/annunciator.light_3_2",1);
			}else{
				setprop("/sim/alarms/annunciator.light_3_2",0);
			}
			if(!battery_click){
				setprop("/sim/alarms/annunciator.light_2_2",1);
				
			}else{
				setprop("/sim/alarms/annunciator.light_2_2",0);
			}
			
			var chip_detection = getprop("/engines/pt6a/chip");
			if(chip_detection>0.5){
				setprop("/sim/alarms/annunciator.light_2_4",1);
			}
			
			var low_pitch_prop = pc6.engine.power_reverse.getValue();
			var wow1 = getprop("/gear/gear[1]/wow");
			var wow2 = getprop("/gear/gear[2]/wow");
			if(low_pitch_prop!=nil and low_pitch_prop>0 and !wow1 and !wow2){
				setprop("/sim/alarms/annunciator.light_1_1",1);
			}else{
				setprop("/sim/alarms/annunciator.light_1_1",0);
			}
			
			var deice = getprop("/instrumentation/deice/serviceable");
			if(deice){
				setprop("/sim/alarms/annunciator.light_1_5",1);
			}else{
				setprop("/sim/alarms/annunciator.light_1_5",0);
			}
			
			###### beta range annunciator, to help the virtual pilot
			var beta_range = getprop("/controls/engines/pt6a/power_beta");
			if(beta_range){
				setprop("/sim/alarms/annunciator.light_2_5",1);
			}else{
				setprop("/sim/alarms/annunciator.light_2_5",0);
			}
			
			##for testing the electrical circuit ...
			#var cptfan = getprop("/instrumentation/cockpit-fan/serviceable");
			#if(cptfan){
			#	setprop("/sim/alarms/annunciator.light_2_5",1);
			#}else{
			#	setprop("/sim/alarms/annunciator.light_2_5",0);
		
		}
		
	}else{
	  setprop("/sim/alarms/caution-warning",0);
	  setprop("/sim/alarms/warning-warning",0);
	  
	  setprop("/sim/alarms/annunciator.light_1_1",0);
	  setprop("/sim/alarms/annunciator.light_2_1",0);
	  setprop("/sim/alarms/annunciator.light_3_1",0);
	  setprop("/sim/alarms/annunciator.light_4_1",0);
	  setprop("/sim/alarms/annunciator.light_1_2",0);
	  setprop("/sim/alarms/annunciator.light_2_2",0);
	  setprop("/sim/alarms/annunciator.light_3_2",0);
	  setprop("/sim/alarms/annunciator.light_4_2",0);
	  setprop("/sim/alarms/annunciator.light_1_3",0);
	  setprop("/sim/alarms/annunciator.light_2_3",0);
	  setprop("/sim/alarms/annunciator.light_3_3",0);
	  setprop("/sim/alarms/annunciator.light_4_3",0);
	  setprop("/sim/alarms/annunciator.light_1_4",0);
	  setprop("/sim/alarms/annunciator.light_2_4",0);
	  setprop("/sim/alarms/annunciator.light_3_4",0);
	  setprop("/sim/alarms/annunciator.light_4_4",0);
	  setprop("/sim/alarms/annunciator.light_1_5",0);
	  setprop("/sim/alarms/annunciator.light_2_5",0);
	  setprop("/sim/alarms/annunciator.light_3_5",0);
	  setprop("/sim/alarms/annunciator.light_4_5",0);
	}

	settimer(update_annunciators,0);
}

var fuel_press_caution_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_1_3")){
		setprop("/sim/alarms/caution-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_1_3",fuel_press_caution_toogle,0,0);

var battery_caution_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_2_2")){
		setprop("/sim/alarms/caution-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_2_2",battery_caution_toogle,0,0);

var generator_caution_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_3_2")){
		setprop("/sim/alarms/caution-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_3_2",generator_caution_toogle,0,0);

var alternator_warning_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_3_1")){
		setprop("/sim/alarms/warning-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_3_1",alternator_warning_toogle,0,0);

var battery_warning_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_2_1")){
		setprop("/sim/alarms/warning-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_2_1",battery_warning_toogle,0,0);

var chip_warning_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_2_4")){
		setprop("/sim/alarms/caution-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_2_4",chip_warning_toogle,0,0);

var lowpitch_warning_toogle = func{
	if(getprop("/sim/alarms/annunciator.light_1_1")){
		setprop("/sim/alarms/warning-warning",1);
	}
}
setlistener("/sim/alarms/annunciator.light_1_1",lowpitch_warning_toogle,0,0);

################# test
var warning_test = func{
	var warning_click = getprop("/controls/switches/cockpit_fan-click");
	
	setprop("/sim/model/particles",warning_click);
#	if(warning_click){
#		pc6.alternator.toggleServiceable(0);
#	}else{
#		pc6.alternator.toggleServiceable(1);
#	}
}

setlistener("/controls/switches/cockpit_fan-click", warning_test,0,0);