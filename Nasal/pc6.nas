var fuel_used_value = 0;
var last_fuel_read = 0;
var g_dt = 0;

var init = func {
	fuel_at_start = getprop("/consumables/fuel/total-fuel-lbs");
	#print("Initialising urban effect and sone things else");
	#setprop("/sim/rendering/quality-level",2);
	#setprop("/sim/rendering/urban-shader",1);
	#setprop("/sim/rendering/transition-shader",1);
	#setprop("/sim/rendering/random-vegetation",1);
	
	last_fuel_read = getprop("/consumables/fuel/total-fuel-lbs");
	print("Init Nasal PC6-B2H4 ...done");
	
	
	main_loop();
}

#activation des timers pour les lumieres clignotantes
var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0.05, 0.05, 0.05, 1 ], "/controls/lighting/beacon" );
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0.05, 0.05, 0.05, 0.05, 0.05, 0.35 ], "/controls/lighting/strobe" );

# Setup listener call to start update loop once the fdm is initialized
setlistener("sim/signals/fdm-initialized", init);

#main loop
var main_loop = func {

	fuel_used();
	
	stall_horn();
	
	##failures
	check_g_load();
	check_vne_flaps();
	check_vne_structure();
	
	settimer(main_loop, 0);
}

#fuel used, for the fuel used instrument
var fuel_used = func{
	if(last_fuel_read==nil){
		last_fuel_read = getprop("/consumables/fuel/total-fuel-lbs");
	}
	var fuel_read = getprop("/consumables/fuel/total-fuel-lbs");
	if(fuel_read!=nil and last_fuel_read!=nil){
		var fuel_used_delta = last_fuel_read - fuel_read;
		if(fuel_used_delta<0){
			fuel_used_delta = 0;
		}
		if(getprop("/instrumentation/fuel-used-indicator/serviceable")){
			fuel_used_value = fuel_used_value + fuel_used_delta;
		}
		last_fuel_read = fuel_read;
		
		if(fuel_used_value>999.99){
			fuel_used_value = 999.99;
		}
		setprop("/consumables/fuel/total-fuel-used-lbs",fuel_used_value);
	}
}

#fuel used reset, for the fuel used instrument
var reset_fuel_used = func{
	fuel_used_value = 0;
}

#activation de la stall horn
var stall_horn = func{
	var alert = 0;
	var kias = getprop("velocities/airspeed-kt");
	var wow1 = getprop("gear/gear[1]/wow");
	var wow2 = getprop("gear/gear[2]/wow");
	var button_click = getprop("/controls/switches/stall_annunciator-click");
	if(getprop("/instrumentation/annunciators/stall-warning/serviceable")){
		var stall_speed = 58 - (getprop("/controls/flight/flaps")*6);
		if((kias<stall_speed and !wow1 and !wow2) or button_click==0){
			alert=1;
		}
	}
	setprop("/sim/alarms/stall-warning",alert);
}

#changer les positions des phares d'atterrissage
var adjust_left_landing_light = func{
	var pos = getprop("/controls/lighting/landing-lights-pos-L");
	var pos_switch = getprop("/controls/switches/pos_landing_L-click");
	
	if(getprop("/controls/lighting/pos-landing-lights-L-serviceable")==1){
		if(pos_switch == 1 and pos<1){
			pos = pos + 0.1;
			setprop("/controls/lighting/landing-lights-pos-L",pos);
		}else if(pos_switch == -1 and pos>0){
			pos = pos - 0.1;
			setprop("/controls/lighting/landing-lights-pos-L",pos);
		}
	}
}

var adjust_right_landing_light = func{
	var pos = getprop("/controls/lighting/landing-lights-pos-R");
	var pos_switch = getprop("/controls/switches/pos_landing_R-click");
	
	if(getprop("/controls/lighting/pos-landing-lights-R-serviceable")==1){
		if(pos_switch == 1 and pos<1){
			pos = pos + 0.1;
			setprop("/controls/lighting/landing-lights-pos-R",pos);
		}else if(pos_switch == -1 and pos>0){
			pos = pos - 0.1;
			setprop("/controls/lighting/landing-lights-pos-R",pos);
		}
	}
}

setlistener("/controls/switches/pos_landing_L-click",adjust_left_landing_light);
setlistener("/controls/switches/pos_landing_R-click",adjust_right_landing_light);

# Terrain lookup function, for testing (et peut etre test de crash, etc ...)
var terrain_loockup = func {

   var lat = getprop("/position/latitude-deg");
   var lon = getprop("/position/longitude-deg");
   setprop("/environment/terrain_lookup/latitude",lat);
   setprop("/environment/terrain_lookup/longitude",lon);
   
   if(lat != nil and lon != nil)
   {
      # Get Geo-Info
      var info = geodinfo(lat, lon);

      if(info != nil){
         if (info[1] != nil){
			var names = props.globals.getNode("/environment/terrain_lookup/names");
			if(names!=nil){
				names.removeChildren();
			}
		 
            forindex(i; info[1].names){
				setprop("/environment/terrain_lookup/names/names["~i~"]",info[1].names[i]);
            }
			if(getprop("/environment/terrain_lookup/names/names")!=nil and substr(getprop("/environment/terrain_lookup/names/names"),0,1)=="p"){
				setprop("/environment/terrain_lookup/dust_color",1);
			}else{
				setprop("/environment/terrain_lookup/dust_color",0);
			}
			setprop("/environment/terrain_lookup/light_coverage",info[1].light_coverage);
			setprop("/environment/terrain_lookup/bumpiness",info[1].bumpiness);
			setprop("/environment/terrain_lookup/load_resistance",info[1].load_resistance);
			setprop("/environment/terrain_lookup/solid",info[1].solid);
			setprop("/environment/terrain_lookup/friction_factor",info[1].friction_factor);
			setprop("/environment/terrain_lookup/rolling_friction",info[1].rolling_friction);
			setprop("/environment/terrain_lookup/bumpiness",info[1].bumpiness);
         }
      }
   }

   settimer(terrain_loockup, 0.1);
}

setlistener("/sim/signals/fdm-initialized", terrain_loockup);

var check_g_load = func{
	var g_load = getprop("/accelerations/pilot-g");
	if(g_load!=nil and (g_load>3.58 or g_load<-1.43)){
		g_dt = g_dt + 1;
	}else{
		g_dt = 0;
	}

	if(g_dt>5){
		setprop("/controls/flight/wing_destroyed",1);
		setprop("/sim/sound/crash",1);
		setprop("/sim/messages/copilot","Too much G load !!!!!!!!!!!!!");
	}
}

var check_vne_flaps = func{
	var kias = getprop("velocities/airspeed-kt");
	var flaps = getprop("/controls/flight/flaps");
	if(kias!=nil and kias>95 and flaps!=nil and flaps>0){
		setprop("/sim/failure-manager/controls/flight/flaps/serviceable",0);
#		setprop("/sim/sound/crash",1);
		setprop("/sim/messages/copilot","VNE for flaps exceed !!!!!!!!!!!!!");
	}
}

var	check_vne_structure = func{
	var kias = getprop("velocities/airspeed-kt");
	if(kias!=nil and kias>151){
		setprop("/controls/flight/wing_destroyed",1);
		setprop("/sim/sound/crash",1);
		setprop("/sim/messages/copilot","VNE exceed !!!!!!!!!!!!!");
	}
}
