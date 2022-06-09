##
# Initialize the instrument system
##

var init_instruments = func {
	print("Nasal Instrument System Initialized");
	
	settimer(adjust_prop_affich,0);
}

setlistener("sim/signals/fdm-initialized", init_instruments);

var adjust_prop_affich = func{
	if(getprop("/instrumentation/rpm-indicator/serviceable")){
		interpolate("/instrumentation/rpm-percent-indicator/valeur",0+getprop("/engines/pt6a/turbine_percent_rpm"),1);
		interpolate("/instrumentation/rpm-indicator/valeur",0+getprop("/engines/pt6a/prop_rpm"),1);
	}else{
		interpolate("/instrumentation/rpm-percent-indicator/valeur",0,1);
		interpolate("/instrumentation/rpm-indicator/valeur",0,1);
	}
	if(getprop("/instrumentation/itt-indicator/serviceable")){
		interpolate("/instrumentation/itt-indicator/valeur",0+getprop("/engines/pt6a/turbine_itt"),1);
	}else{
		interpolate("/instrumentation/itt-indicator/valeur",0,1);
	}
	if(getprop("/instrumentation/torque-indicator/serviceable")){
		interpolate("/instrumentation/torque-indicator/valeur",0+getprop("/engines/pt6a/prop_torque"),1);
	}else{
		interpolate("/instrumentation/torque-indicator/valeur",0,1);
	}
	if(getprop("/instrumentation/fuelflow-indicator/serviceable")){
		interpolate("/instrumentation/fuelflow-indicator/valeur",0+getprop("/engines/pt6a/fuel_flow"),1);
	}else{
		interpolate("/instrumentation/fuelflow-indicator/valeur",0,1);
	}
	
	if(getprop("/instrumentation/fuel-qty-indicator/serviceable")){
		interpolate("/instrumentation/fuel-qty-indicator[0]/valeur",0+getprop("/consumables/fuel/tank[0]/level-gal_us"),1);
		interpolate("/instrumentation/fuel-qty-indicator[1]/valeur",0+getprop("/consumables/fuel/tank[1]/level-gal_us"),1);
	}else{
		interpolate("/instrumentation/fuel-qty-indicator[0]/valeur",0,1);
		interpolate("/instrumentation/fuel-qty-indicator[1]/valeur",0,1);
	}
	
	if(getprop("/instrumentation/oil-indicator/serviceable")){
		interpolate("/instrumentation/oil-indicator/temp_valeur",0+getprop("/engines/pt6a/oil_temp"),1);
		interpolate("/instrumentation/oil-indicator/psi_valeur",0+getprop("/engines/pt6a/oil_psi"),1);
	}else{
		interpolate("/instrumentation/oil-indicator/temp_valeur",0,1);
		interpolate("/instrumentation/oil-indicator/psi_valeur",0,1);
	}
	
	
	
	
	settimer(adjust_prop_affich,0);
}

