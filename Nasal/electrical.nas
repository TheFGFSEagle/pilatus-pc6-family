##
# pc6 b2h4 electrical system.
# Edit of pa24-250 electrical system file using information from 
# 
##

# Initialize internal values
#

var battery = nil;
var alternator = nil;

var last_time = 0.0;
var vcutoff = 12.0;
var ammeter_lowpass = aircraft.lowpass.new(0.5);

##
# Initialize the electrical system
##

var init_electrical = func {
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

	print("Nasal Electrical System Initialized");  
	
    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

# Setup listener call to initialize the electrical system once the fdm is initialized
# 
setlistener("/sim/signals/fdm-initialized", init_electrical);  

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 34.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 7.0,
			serviceable : 1};
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    var amphrs_used = amps * dt / 3600.0;
    var percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }

	if(me.charge_percent < 0.05){#battery out of order if charge decrease to 5 % !!!
		me.toggleServiceable(0);
	}
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
	var result = me.ideal_volts * factor;
	if(!me.isServiceable()){
		result = 0;
	}
    return result;
}


BatteryClass.get_output_amps = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    var result = me.ideal_amps * factor;
	if(!me.isServiceable()){
		result = 0;
	}
    return result;
}

BatteryClass.isServiceable = func() {
    return me.serviceable;
}

BatteryClass.toggleServiceable = func(state) {
	me.serviceable = state;
	setprop("/systems/electrical/battery/serviceable",me.serviceable);
}

AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/pt6a/turbine_rpm",
			rpm_threshold : 22500.0, # the turbine operate from 0 to 37500, the generator from 0 to ~12000 and provide volts at 7200
            ideal_volts : 28.0,
            ideal_amps : 200.0,
			serviceable : 1};
    return obj;
}


AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < rpm_threshold.  For rpms >= rpm_threshold
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    var available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}

AlternatorClass.isServiceable = func() {
    return me.serviceable;
}

AlternatorClass.toggleServiceable = func(state) {
	me.serviceable = state;
	setprop("/systems/electrical/alternator/serviceable",me.serviceable);
}

var update_electrical = func {
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;

	update_output(dt);

    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}

var update_annunciators_bus = func(dt){
	var master_bat = getprop("/controls/switches/battery-click");
	var master_alt = getprop("/controls/switches/generator-click");
	var battery_volts = battery.get_output_volts();
	var alternator_volts = alternator.get_output_volts();
	var load = 0.0;
	var totalVolt = 0.0;
	
	if(master_bat and getprop("/controls/electric/circuitbreaker/cb_3_4") and battery.isServiceable()){
		totalVolt = battery_volts;
		load = 4.5;
	}
	
	
	if ( master_alt and (alternator_volts > totalVolt) and getprop("/controls/electric/circuitbreaker/cb_3_5") and alternator.isServiceable()) {
		totalVolt = alternator_volts;
		load = 4.5;
	}
	
	setprop("/systems/electrical/outputs/annunciators", totalVolt);
	if(totalVolt>vcutoff){
		# Annunciators Power
		setprop("/instrumentation/annunciators/general/serviceable", 1);
	}else{
		setprop("/instrumentation/annunciators/general/serviceable", 0);
	}
	
	return load;
}

var update_radio_bus = func(dt){
	var master_bat = getprop("/controls/switches/battery-click");
	var bat_cb = getprop("/controls/electric/circuitbreaker/cb_1_3");
	var bat_bus_click = getprop("/controls/switches/bat_bus-click");
	var master_alt = getprop("/controls/switches/generator-click");
	var alt_cb = getprop("/controls/electric/circuitbreaker/cb_1_6");
	var alt_bus_click = getprop("/controls/switches/gen_bus-click");
	var battery_volts = battery.get_output_volts();
	var alternator_volts = alternator.get_output_volts();
	var radio_bus_cb = getprop("/controls/electric/circuitbreaker/bus_breaker");
	var load = 0.0;
	var totalVolt = 0.0;
	
	
	if(master_bat and bat_cb and bat_bus_click and radio_bus_cb and battery.isServiceable()){
		totalVolt = battery_volts;
	}
	
	if ( master_alt and alternator_volts > totalVolt and alt_cb and alt_bus_click and radio_bus_cb and alternator.isServiceable()) {
		totalVolt = alternator_volts;
	}

	if(totalVolt>vcutoff){
		# radio Power
		setprop("/systems/electrical/outputs/bus_radio", totalVolt);
		setprop("/instrumentation/bus_radio/serviceable", 1);
		
		#connection des appareils radio
		setprop("/systems/electrical/outputs/comm[0]",totalVolt);
		setprop("/systems/electrical/outputs/comm[1]",totalVolt);
		setprop("/systems/electrical/outputs/transponder",totalVolt);
		setprop("/systems/electrical/outputs/radiomixer",totalVolt);
		setprop("/systems/electrical/outputs/gps",totalVolt);
	}else{
		setprop("/systems/electrical/outputs/bus_radio", 0);
		setprop("/instrumentation/bus_radio/serviceable", 0);
		setprop("/systems/electrical/outputs/comm[0]",0);
		setprop("/systems/electrical/outputs/comm[1]",0);
		setprop("/systems/electrical/outputs/transponder",0);
		setprop("/systems/electrical/outputs/radiomixer",0);
		setprop("/systems/electrical/outputs/gps",0);
	}
	
	if(getprop("/instrumentation/bus_radio/serviceable")){
		if(getprop("/controls/electric/circuitbreaker/cbr_1_1")){
			if(getprop("/instrumentation/comm[0]/serviceable")){
				load += 6; #1 en reception, 6 en emmision, on va considerer qu'on emet tout le temps ...
			}
		}else{
			setprop("/systems/electrical/outputs/comm[0]",0);
		}
		
		if(getprop("/controls/electric/circuitbreaker/cbr_1_4")){
			load += 1;
		}else{
			setprop("/systems/electrical/outputs/radiomixer",0);
		}
		
		if(getprop("/controls/electric/circuitbreaker/cbr_1_8")){
			if(getprop("/instrumentation/comm[1]/serviceable")){
				load += 6; #1 en reception, 6 en emmision, on va considerer qu'on emet tout le temps ...
			}
		}else{
			setprop("/systems/electrical/outputs/comm[1]",0);
		}
		

		if(getprop("/controls/electric/circuitbreaker/cbr_1_2") and getprop("/controls/electric/circuitbreaker/cbr_1_3")){
			if(getprop("/instrumentation/transponder/serviceable")){
				load += 4; #aucune idee de la consommation du kt76a ...
			}
		}else{
			setprop("/systems/electrical/outputs/transponder",0);
		}
		
		if(getprop("/controls/electric/circuitbreaker/cbr_2_5")){
			load += 2;
		}else{
			setprop("/systems/electrical/outputs/gps",0);
		}
	}
	
	return load;
}

var update_virtual_bus = func(dt,totalVolt){
	var load = 0.0;
	
	if(totalVolt>vcutoff){
		# Nav Lights Power
		if ( getprop("/controls/switches/light_position-click")  and getprop("/controls/electric/circuitbreaker/cb_3_3")) {
			setprop("/systems/electrical/outputs/position-lights", totalVolt);
			setprop("/controls/lighting/nav-lights", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/position-lights", 0.0);
			setprop("/controls/lighting/nav-lights", 0);
		}

		# Trim Power
		if (getprop("/controls/electric/circuitbreaker/cb_2_4")) {
			setprop("/systems/electrical/outputs/stab-trim", totalVolt);
			setprop("/instrumentation/trim/serviceable", 1);
			load += 6;
		} else {
			setprop("/systems/electrical/outputs/stab-trim", 0.0);
			setprop("/instrumentation/trim/serviceable", 0);
		}
		
		# Left landing Light Power
		if ( getprop("/controls/switches/light_landing_L-click")  and getprop("/controls/electric/circuitbreaker/cb_3_2")) {
			setprop("/systems/electrical/outputs/landing-lights-L", totalVolt);
			setprop("/controls/lighting/landing-lights-L", 1);
			load += 9;
		} else {
			setprop("/systems/electrical/outputs/landing-lights-L", 0.0);
			setprop("/controls/lighting/landing-lights-L", 0);
		}
		
		# Left landing Light Power
		if ( getprop("/controls/electric/circuitbreaker/cb_3_2")) {
			setprop("/systems/electrical/outputs/pos-landing-lights-L", totalVolt);
			setprop("/controls/lighting/pos-landing-lights-L-serviceable", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/pos-landing-lights-L", 0.0);
			setprop("/controls/lighting/pos-landing-lights-L-serviceable", 0);
		}
		
		# Beacon Lights Power
		if ( getprop("/controls/switches/light_beacon-click")  and getprop("/controls/electric/circuitbreaker/cb_3_3")) {
			setprop("/systems/electrical/outputs/beacon-lights", totalVolt);
			setprop("/controls/lighting/beacon", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/beacon-lights", 0.0);
			setprop("/controls/lighting/beacon", 0);
		}
		
		# Deice Power
		if ( getprop("/controls/electric/circuitbreaker/cb_5_1") and getprop("/controls/switches/deice-click")) {
			setprop("/systems/electrical/outputs/deice", totalVolt);
			setprop("/instrumentation/deice/serviceable", 1);
			load += 6;
		} else {
			setprop("/systems/electrical/outputs/deice", 0.0);
			setprop("/instrumentation/deice/serviceable", 0);
		}
		
		# Cockpit fan Power
		if ( getprop("/controls/electric/circuitbreaker/cb_2_1") and getprop("/controls/switches/cockpit_fan-click")) {
			setprop("/systems/electrical/outputs/cockpit-fan", totalVolt);
			setprop("/instrumentation/cockpit-fan/serviceable", 1);
			load += 4.5;
		} else {
			setprop("/systems/electrical/outputs/cockpit-fan", 0.0);
			setprop("/instrumentation/cockpit-fan/serviceable", 0);
		}
		
		# Stall warn Power
		if ( getprop("/controls/electric/circuitbreaker/cb_5_2")) {
			setprop("/systems/electrical/outputs/stall-warn", totalVolt);
			setprop("/instrumentation/annunciators/stall-warning/serviceable", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/stall-warn", 0.0);
			setprop("/instrumentation/annunciators/stall-warning/serviceable", 0);
		}
		
		# Heading-indicator Power
		if (getprop("/controls/electric/circuitbreaker/cb_5_3")) {
			setprop("/systems/electrical/outputs/heading-indicator", totalVolt);
			setprop("/instrumentation/heading-indicator/serviceable", 1);
			load += 1.8;
		} else {
			setprop("/systems/electrical/outputs/heading-indicator", 0.0);
			setprop("/instrumentation/heading-indicator/serviceable", 0);
		}
		
		# Fuel Flow and RPM Power
		if (getprop("/controls/electric/circuitbreaker/cb_4_3")) {
			setprop("/systems/electrical/outputs/rpm-indicator", totalVolt);
			setprop("/instrumentation/rpm-indicator/serviceable", 1);
			setprop("/systems/electrical/outputs/rpm-percent-indicator", totalVolt);
			setprop("/instrumentation/rpm-percent-indicator/serviceable", 1);
			setprop("/systems/electrical/outputs/fuelflow-indicator", totalVolt);
			setprop("/instrumentation/fuelflow-indicator/serviceable", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/rpm-indicator", 0.0);
			setprop("/instrumentation/rpm-indicator/serviceable", 0);
			setprop("/systems/electrical/outputs/rpm-percent-indicator", 0.0);
			setprop("/instrumentation/rpm-percent-indicator/serviceable", 0);
			setprop("/systems/electrical/outputs/fuelflow-indicator", 0.0);
			setprop("/instrumentation/fuelflow-indicator/serviceable", 0);
		}
		
		# Torque and ITT Power
		if (getprop("/controls/electric/circuitbreaker/cb_4_4")) {
			setprop("/systems/electrical/outputs/torque-indicator", totalVolt);
			setprop("/instrumentation/torque-indicator/serviceable", 1);
			setprop("/systems/electrical/outputs/itt-indicator", totalVolt);
			setprop("/instrumentation/itt-indicator/serviceable", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/torque-indicator", 0.0);
			setprop("/instrumentation/torque-indicator/serviceable", 0);
			setprop("/systems/electrical/outputs/itt-indicator", 0.0);
			setprop("/instrumentation/itt-indicator/serviceable", 0);
		}
		
		# Starter Power
		if ( getprop("/controls/switches/starter-click")  and getprop("/controls/electric/circuitbreaker/cb_1_1")) {
			setprop("/systems/electrical/outputs/starter", totalVolt);
			setprop("/instrumentation/starter/serviceable", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/starter", 0.0);
			setprop("/instrumentation/starter/serviceable", 0);
		}
				
		# Ignition Power
		if ( getprop("/controls/switches/ignition-click")  and getprop("/controls/electric/circuitbreaker/cb_1_2")) {
			setprop("/systems/electrical/outputs/ignition", totalVolt);
			setprop("/instrumentation/ignition/serviceable", 1);
			load += 6;
		} else {
			setprop("/systems/electrical/outputs/ignition", 0.0);
			setprop("/instrumentation/ignition/serviceable", 0);
		}

		# Aux fuel pump Power
		if ( getprop("/controls/switches/aux_fuel_pump-click")  and getprop("/controls/electric/circuitbreaker/cb_5_6")) {
			setprop("/systems/electrical/outputs/aux_fuel_pump", totalVolt);
			setprop("/instrumentation/aux_fuel_pump/serviceable", 1);
			load += 4.5;
		} else {
			setprop("/systems/electrical/outputs/aux_fuel_pump", 0.0);
			setprop("/instrumentation/aux_fuel_pump/serviceable", 0);
		}
		
		# Cabin Lights Power
		if ( getprop("/controls/switches/light_cabin-click") and getprop("/controls/electric/circuitbreaker/cb_3_8") ) {
			setprop("/systems/electrical/outputs/cabin-lights", totalVolt);
			setprop("/controls/lighting/light_cabin", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/cabin-lights", 0.0);
			setprop("/controls/lighting/light_cabin", 0);
		}
		
		# Right landing Light Power
		if ( getprop("/controls/switches/light_landing_R-click")  and getprop("/controls/electric/circuitbreaker/cb_3_7")) {
			setprop("/systems/electrical/outputs/landing-lights-R", totalVolt);
			setprop("/controls/lighting/landing-lights-R", 1);
			load += 6;
		} else {
			setprop("/systems/electrical/outputs/landing-lights-R", 0.0);
			setprop("/controls/lighting/landing-lights-R", 0);
		}

		# Right landing Light Power
		if ( getprop("/controls/electric/circuitbreaker/cb_3_7")) {
			setprop("/systems/electrical/outputs/pos-landing-lights-R", totalVolt);
			setprop("/controls/lighting/pos-landing-lights-R-serviceable", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/pos-landing-lights-R", 0.0);
			setprop("/controls/lighting/pos-landing-lights-R-serviceable", 0);
		}

		# Strobe Lights Power
		if ( getprop("/controls/switches/light_strobe-click")  and getprop("/controls/electric/circuitbreaker/cb_3_6")) {
			setprop("/systems/electrical/outputs/strobe-lights", totalVolt);
			setprop("/controls/lighting/strobe", 1);
			load += 6;
		} else {
			setprop("/systems/electrical/outputs/strobe-lights", 0.0);
			setprop("/controls/lighting/strobe", 0);
		}
		
		# Instruments Lights Power
		var pos_instrument_knob = getprop("/controls/switches/instrument-lights-norm");
		if ( getprop("/controls/switches/light_instr-click")  and getprop("/controls/electric/circuitbreaker/cb_1_8")) {
			setprop("/systems/electrical/outputs/instr-lights", totalVolt);
			setprop("/systems/electrical/outputs/instrument-lights-norm", pos_instrument_knob);
			load += 4.5;
		} else {
			setprop("/systems/electrical/outputs/instr-lights", 0.0);
			setprop("/systems/electrical/outputs/instrument-lights-norm", 0);
		}
			
		# Turn-indicator Power
		if (getprop("/controls/electric/circuitbreaker/cb_4_8")) {
			setprop("/systems/electrical/outputs/turn-coordinator", totalVolt);
			setprop("/instrumentation/turn-indicator/serviceable", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
			setprop("/instrumentation/turn-indicator/serviceable", 0);
		}
		
		# Fuel qty and Fuel used Power
		if (getprop("/controls/electric/circuitbreaker/cb_4_6")) {
			setprop("/systems/electrical/outputs/fuel-qty", totalVolt);
			setprop("/instrumentation/fuel-qty-indicator/serviceable", 1);
			setprop("/systems/electrical/outputs/fuel-used", totalVolt);
			setprop("/instrumentation/fuel-used-indicator/serviceable", 1);
			load += 3;
		} else {
			setprop("/systems/electrical/outputs/fuel-qty", 0.0);
			setprop("/instrumentation/fuel-qty-indicator/serviceable", 0);
			setprop("/systems/electrical/outputs/fuel-used", 0.0);
			setprop("/instrumentation/fuel-used-indicator/serviceable", 0);
		}
		
		# Oil psi and temp Power
		if (getprop("/controls/electric/circuitbreaker/cb_4_5")) {
			setprop("/systems/electrical/outputs/oil", totalVolt);
			setprop("/instrumentation/oil-indicator/serviceable", 1);
			load += 1.2;
		} else {
			setprop("/systems/electrical/outputs/oil", 0.0);
			setprop("/instrumentation/oil-indicator/serviceable", 0);
		}
	}else{
		setprop("/systems/electrical/outputs/position-lights", 0.0);
		setprop("/controls/lighting/nav-lights", 0);
		setprop("/systems/electrical/outputs/stab-trim", 0.0);
		setprop("/instrumentation/trim/serviceable", 0);
		setprop("/systems/electrical/outputs/landing-lights-L", 0.0);
		setprop("/controls/lighting/landing-lights-L", 0);
		setprop("/systems/electrical/outputs/pos-landing-lights-L", 0.0);
		setprop("/controls/lighting/pos-landing-lights-L-serviceable", 0);
		setprop("/systems/electrical/outputs/beacon-lights", 0.0);
		setprop("/controls/lighting/beacon", 0);
		setprop("/systems/electrical/outputs/stall-warn", 0.0);
		setprop("/instrumentation/annunciators/stall-warning/serviceable", 0);
		setprop("/systems/electrical/outputs/heading-indicator", 0.0);
		setprop("/instrumentation/heading-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/rpm-indicator", 0.0);
		setprop("/instrumentation/rpm-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/rpm-percent-indicator", 0.0);
		setprop("/instrumentation/rpm-percent-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/fuelflow-indicator", 0.0);
		setprop("/instrumentation/fuelflow-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/torque-indicator", 0.0);
		setprop("/instrumentation/torque-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/itt-indicator", 0.0);
		setprop("/instrumentation/itt-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/starter", 0.0);
		setprop("/instrumentation/starter/serviceable", 0);
		setprop("/systems/electrical/outputs/ignition", 0.0);
		setprop("/instrumentation/ignition/serviceable", 0);
		setprop("/systems/electrical/outputs/aux_fuel_pump", 0.0);
		setprop("/instrumentation/aux_fuel_pump/serviceable", 0);
		setprop("/systems/electrical/outputs/cabin-lights", 0.0);
		setprop("/controls/lighting/light_cabin", 0);
		setprop("/systems/electrical/outputs/landing-lights-R", 0.0);
		setprop("/controls/lighting/landing-lights-R", 0);
		setprop("/systems/electrical/outputs/pos-landing-lights-R", 0.0);
		setprop("/controls/lighting/pos-landing-lights-R-serviceable", 0);
		setprop("/systems/electrical/outputs/strobe-lights", 0.0);
		setprop("/controls/lighting/strobe", 0);
		setprop("/systems/electrical/outputs/instr-lights", 0.0);
		setprop("/systems/electrical/outputs/instrument-lights-norm", 0);
		setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
		setprop("/instrumentation/turn-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/fuel-qty", 0.0);
		setprop("/instrumentation/fuel-qty-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/fuel-used", 0.0);
		setprop("/instrumentation/fuel-used-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/oil", 0.0);
		setprop("/instrumentation/oil-indicator/serviceable", 0);
		setprop("/systems/electrical/outputs/deice", 0.0);
		setprop("/instrumentation/deice/serviceable", 0);
		setprop("/systems/electrical/outputs/cockpit-fan", 0.0);
		setprop("/instrumentation/cockpit-fan/serviceable", 0);
	}
	
	return load;
}

var update_output = func(dt){
	var load = 0;
	var totalVolt = 0;
	var alternator_volts = alternator.get_output_volts();
	var battery_volts = battery.get_output_volts();
	
	# switch state
    var master_bat = getprop("/controls/switches/battery-click");
    var master_alt = getprop("/controls/switches/generator-click");
	var power_source = nil;
	
	if ( master_bat and battery.isServiceable()) {
		totalVolt = battery_volts;
		power_source = "battery";
    }
	
	##to inoperate the alternator when the starter is running
	if(master_alt and getprop("/systems/electrical/outputs/starter")>0 and getprop("/instrumentation/starter/serviceable")){
		alternator.toggleServiceable(0);
	}
	
	##reset the generator, to set it operative if we are lucky ...
	var alt_reset = getprop("/controls/switches/gen-reset-click");
	if(alt_reset and master_bat and battery.isServiceable()){
		if(!master_alt){##the alternator must be disconnect
			if(rand()>0.99){
				alternator.toggleServiceable(1);
			}
		}
	}
	
	if ( master_alt and alternator_volts > totalVolt and alternator_volts > vcutoff and alternator.isServiceable()) {
		totalVolt = alternator_volts;
		power_source = "alternator";
	}

	# system loads and ammeter gauge
    ammeter = 0.0;
	load += update_virtual_bus(dt,totalVolt);
	load += update_annunciators_bus(dt);
	load += update_radio_bus(dt);
	# ammeter gauge
	if ( power_source == "battery" ) {
		ammeter = -load;
	} elsif ( power_source == "alternator"){
		load += battery.charge_amps;
		ammeter = alternator.apply_load(load,dt);

		#ammeter = battery.charge_amps;
	}


	# charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( power_source == "alternator") {
        battery.apply_load( -battery.charge_amps, dt );
    }

	# outputs
    setprop("/systems/electrical/amps", ammeter_lowpass.filter(ammeter));
    setprop("/systems/electrical/volts", totalVolt);

    return load;
}

