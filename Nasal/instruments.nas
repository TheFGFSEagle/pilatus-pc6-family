var adjust_prop_affich = func{
	if(getprop("/instrumentation/rpm-indicator/serviceable")){
		interpolate("/instrumentation/rpm-percent-indicator/valeur",0+getprop("/engines/pt6a/turbine_percent_rpm"),1);
		interpolate("/instrumentation/rpm-indicator/valeur",0+getprop("/engines/pt6a/prop_rpm"),1);
	}else{
		interpolate("/instrumentation/rpm-percent-indicator/valeur",0,1);
		interpolate("/instrumentation/rpm-indicator/valeur",0,1);
	}
	if(getprop("/instrumentation/torque-indicator/serviceable")){
		interpolate("/instrumentation/torque-indicator/valeur",0+getprop("/engines/pt6a/prop_torque"),1);
	}else{
		interpolate("/instrumentation/torque-indicator/valeur",0,1);
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

