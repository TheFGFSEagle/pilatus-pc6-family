##
# pc6 b2h4 engine system.
# 
##

# Initialize internal values
#

var engine = nil;

var last_time = 0.0;

##
# Initialize the engine system
##

var init_engine = func {
    engine = EngineClass.new();


	print("Nasal Engine System Initialized");  
	
    # Request that the update fuction be called next frame
    settimer(update_engine, 0);
}

# Setup listener call to initialize the electrical system once the fdm is initialized
# 
setlistener("/sim/signals/fdm-initialized", init_engine);  

var EngineClass = {
	new : func {
		m = { parents : [EngineClass]};
		
		#m.throttle_lever_yasim = props.globals.getNode("/controls/engines/pt6a/throttle_lever_yasim",1);
		m.power = props.globals.getNode("/controls/engines/pt6a/power",1);
		m.power_reverse = props.globals.getNode("/controls/engines/pt6a/power_reverse",1);
		m.power_beta = props.globals.getNode("/controls/engines/pt6a/power_beta",1);
		m.throttle = props.globals.getNode("/controls/engines/engine[0]/throttle",1);
		
		m.pitch_lever = props.globals.getNode("/engines/pt6a/propeller-pitch-lever",1);
		m.pitch = props.globals.getNode("/engines/pt6a/propeller-pitch",1);
		
		m.prop_rpm = props.globals.getNode("/engines/pt6a/prop_rpm",1);
		m.fuel_press = props.globals.getNode("/engines/pt6a/fuel_press",1);
		m.fuel_flow = props.globals.getNode("/engines/pt6a/fuel_flow",1);
		m.fuel_in_chamber = props.globals.getNode("/engines/pt6a/fuel_in_chamber",1);
		m.fuel_in_chamber_liquid = props.globals.getNode("/engines/pt6a/fuel_in_chamber_liquid",1);
		
		m.prop_torque = props.globals.getNode("/engines/pt6a/prop_torque",1);
		m.turbine_rpm = props.globals.getNode("/engines/pt6a/turbine_rpm",1);
		m.turbine_percent_rpm = props.globals.getNode("/engines/pt6a/turbine_percent_rpm",1);
		m.turbine_itt = props.globals.getNode("/engines/pt6a/turbine_itt",1);
		m.oil_psi = props.globals.getNode("/engines/pt6a/oil_psi",1);
		m.oil_temp = props.globals.getNode("/engines/pt6a/oil_temp",1);
		m.condition = props.globals.getNode("/engines/pt6a/condition",1);
		
		m.chip = props.globals.getNode("/engines/pt6a/chip",1);
		
		m.running = props.globals.getNode("/engines/pt6a/running",1);
		m.starting = props.globals.getNode("/engines/pt6a/starting",1);
		m.ignition = props.globals.getNode("/engines/pt6a/ignition",1);
		
		m.failure_turbine = props.globals.getNode("/engines/pt6a/failure/turbine",1);
		m.failure_turbine_thermal_shock = props.globals.getNode("/engines/pt6a/failure/turbine_thermal_shock",1);
		m.failure_propeller = props.globals.getNode("/engines/pt6a/failure/propeller",1);
		m.failure_propeller_blade = props.globals.getNode("/engines/pt6a/failure/propeller-blade",1);

    return m;
	},
	update : func(dt){
		
		#test fuel circuit
		var fuel_valve = props.globals.getNode("/consumables/fuel/switch-position").getValue();
		var fuel_tank = props.globals.getNode("/consumables/fuel/total-fuel-lbs").getValue();
		
		var aux_fuel_pump = getprop("/instrumentation/aux_fuel_pump/serviceable");
		if(aux_fuel_pump or me.turbine_percent_rpm.getValue()>35){#the turbine pump "start" at 35%
			interpolate("/engines/pt6a/fuel_press",1,3);
		}else{
			interpolate("/engines/pt6a/fuel_press",0,3);
		}
		
		var turbine_friction = me.turbine_rpm.getValue();
		var delta = (- turbine_friction)*2;
		
		#starter action
		if(me.starting.getValue() and me.turbine_rpm.getValue()<5625){
			delta = delta + (me.turbine_rpm.getValue()+500)*2;
		}
		
		##difference between external temp and itt set a thermal shock which block the turbine
		if(me.failure_turbine_thermal_shock.getValue()==1){
			delta = -me.turbine_rpm.getValue();
		}
		
		#ignition action
		if(me.ignition.getValue() and me.fuel_in_chamber.getValue()>400 and me.failure_turbine.getValue()==0){
			me.running.setBoolValue(1);
		}
		
		#fuel consumption calculs
		var fuel_consumption = 0;
		if(fuel_valve!=0 and fuel_tank!=0 and me.condition.getValue()!=0){
			if(me.throttle.getValue()>0.42){
				var throttle_tmp = me.throttle.getValue() - 0.42;
				fuel_consumption = throttle_tmp*380 + 285;
			}elsif(me.throttle.getValue()<0.3){
				var throttle_tmp = 0.3 - me.throttle.getValue()*3;
				fuel_consumption = (throttle_tmp*380 + 285)*1.2;
			}else{#dead zone , idle
				fuel_consumption = 285;
			}

			if(fuel_consumption<370 and me.condition.getValue()==2){#high idle
				fuel_consumption = 370;
			}
			if(fuel_consumption<285 and me.condition.getValue()==1){#low idle
				fuel_consumption = 285;
			}
			if(me.condition.getValue()==0){
				fuel_consumption = 0;
			}
			me.fuel_flow.setValue(fuel_consumption*me.fuel_press.getValue());
			
			#parameter used to calculate itt and starting condition
			if(me.turbine_rpm.getValue()>4500){#if the turbine rpm < 15%, the fuel is unusuable for combustion, but elevate the itt ...
				me.fuel_in_chamber.setValue(me.fuel_in_chamber.getValue()+me.fuel_flow.getValue()*dt*0.5);
			}else{
				me.fuel_in_chamber_liquid.setValue(me.fuel_in_chamber_liquid.getValue()+me.fuel_flow.getValue()*dt*0.5);
			}
			if(me.running.getValue()){
				me.fuel_in_chamber.setValue(me.fuel_in_chamber.getValue()-me.turbine_rpm.getValue()*dt/75-100*dt);
				if(me.fuel_in_chamber.getValue()<0){
					me.fuel_in_chamber.setValue(0);
					me.fuel_in_chamber_liquid.setValue(me.fuel_in_chamber_liquid.getValue()-me.turbine_rpm.getValue()*dt/75-100*dt);
					if(me.fuel_in_chamber_liquid.getValue()<0){
						me.fuel_in_chamber_liquid.setValue(0);
					}
				}
			}
			
			var fuel_consumption_tank0 = me.fuel_flow.getValue() / 2;
			var fuel_consumption_tank1 = me.fuel_flow.getValue() / 2;
			if(props.globals.getNode("/consumables/fuel/tank[0]/level-lbs").getValue()<=0){
				fuel_consumption_tank1 = fuel_consumption_tank0 + fuel_consumption_tank1;
				fuel_consumption_tank0 = 0;
				props.globals.getNode("/consumables/fuel/tank[0]/level-lb").setValue(0);
			}
			if(props.globals.getNode("/consumables/fuel/tank[1]/level-lbs").getValue()<=0){
				fuel_consumption_tank0 = fuel_consumption_tank0 + fuel_consumption_tank1;
				fuel_consumption_tank1 = 0;
				props.globals.getNode("/consumables/fuel/tank[1]/level-lbs").setValue(0);
			}
			
			var level_lbs0 = getprop("/consumables/fuel/tank[0]/level-lbs") - dt*fuel_consumption_tank0/3600;
			setprop("/consumables/fuel/tank[0]/level-lbs",level_lbs0);
			var level_lbs1 = getprop("/consumables/fuel/tank[1]/level-lbs") - dt*fuel_consumption_tank1/3600;
			setprop("/consumables/fuel/tank[1]/level-lbs",level_lbs1);
		}else{
			me.fuel_flow.setValue(0);
			me.running.setBoolValue(0);
		}
		
		var turbine_press = me.turbine_rpm.getValue()/18750;
		turbine_press = turbine_press * turbine_press;
		if(turbine_press<1 and me.starting.getValue()){
			turbine_press = 1;
		}
		if(turbine_press>1){
			turbine_press = 1;
		}
			
		#turbine is ignited, it produce power ...
		if(me.running.getValue()){
			var fuel_power = (fuel_consumption * 75)*me.fuel_press.getValue()*turbine_press;
			delta = 2*fuel_power + delta;
		}
		
		#apply power or friction to turbine rpm
		if(delta>3000){
			delta = 3000;
		}elsif(delta<-1500){
			if(me.failure_turbine_thermal_shock.getValue()==0){
				delta = -1500;
			}elsif(delta<-10000){
				delta = -10000;
			}
		}

		me.turbine_rpm.setValue(me.turbine_rpm.getValue() + dt*delta);
		
		#without fuel, the prop run with the turbine
		me.turbine_percent_rpm.setValue(100*me.turbine_rpm.getValue()/37500);
		var prop_rpm_tmp = 1900*me.turbine_rpm.getValue()*me.turbine_rpm.getValue()/770062500;
		var torque_tmp = 0;

		if(prop_rpm_tmp > 2200 and me.pitch.getValue()==1){
			torque_tmp = (prop_rpm_tmp - 2200)/25;
			prop_rpm_tmp = 2200;
		}
		
		##connection between propeller and turbine is broken, the propeller use the speed of the plane to rotate or the turbine is not on
		if((me.failure_propeller.getValue()==1 or me.running.getValue()==0) and getprop("velocities/airspeed-kt")>30){
			prop_rpm_tmp = getprop("velocities/airspeed-kt") * 10;
		}
		
		me.prop_rpm.setValue(me.prop_rpm.getValue() + (prop_rpm_tmp - me.prop_rpm.getValue())*dt);
		me.prop_torque.setValue(torque_tmp);
		
		if(me.throttle.getValue()>=0.42){#power to advance
			me.power_beta.setValue(0);
			me.power.setValue(torque_tmp*0.02);
			me.power_reverse.setValue(0);
		}elsif(me.throttle.getValue()<0.42 and me.throttle.getValue()>=0.38){#idle, no power
			me.power_beta.setValue(0);
			me.power.setValue(0);
			me.power_reverse.setValue(0);
		}elsif(me.throttle.getValue()<0.38 and me.throttle.getValue()>=0.3){#idle, beta range
			me.power_beta.setValue(1);
			me.power.setValue(0);
			me.power_reverse.setValue(0);
		}elsif(me.throttle.getValue()<0.3){#reverse
			me.power_beta.setValue(0);
			me.power.setValue(0);
			me.power_reverse.setValue(torque_tmp*0.02);
		}
		
		#itt calcul
		var itt_actual = me.turbine_itt.getValue();
		var itt_target = getprop("environment/temperature-degc") + turbine_press*200;
		if((me.fuel_in_chamber.getValue()>0 or me.fuel_in_chamber_liquid.getValue()>0) and me.running.getValue()){
			itt_target = itt_target + 1290;
		}
		itt_target = itt_target + (fuel_consumption*fuel_consumption*fuel_consumption*0.00001) - prop_rpm_tmp * 0.027 - torque_tmp * 12.3;
		
		##thermal shock
		if(itt_target<itt_actual and (itt_actual - itt_target)>300 and !me.running.getValue()){
			setprop("/sim/messages/copilot", "Thermal shock between external temperature and ITT !!!");
			me.failure_turbine_thermal_shock.setValue(1);
		}
		itt_actual = itt_actual + (itt_target - itt_actual)*dt/10;
		me.turbine_itt.setValue(itt_actual);
		
		#oil pressure calcul
		#40 psi at start, 80-100 normal 
		var oil_psi_target = 10*math.sqrt(me.turbine_rpm.getValue()/375);
		if(me.failure_propeller.getValue()==1 or me.failure_turbine.getValue()==1){##oil circuit destroyed
			oil_psi_target = 0;
		}
		var oil_psi_actual = me.oil_psi.getValue();
		oil_psi_actual = oil_psi_actual + (oil_psi_target - oil_psi_actual)*dt/2;
		me.oil_psi.setValue(oil_psi_actual);
		####to do oil failure
		
		#oil temp calcul
		#-40-20 at start, normal 10-99
		var oil_temp_target = me.turbine_itt.getValue()/10 + getprop("environment/temperature-degc");
		#the temperature can be adjusted by the left tirette
		oil_temp_target = oil_temp_target - getprop("/controls/switches/tirette.1")*20;
		var oil_temp_actual = me.oil_temp.getValue();
		oil_temp_actual = oil_temp_actual + (oil_temp_target - oil_temp_actual)*dt/5;
		me.oil_temp.setValue(oil_temp_actual);
		####to do oil failure

		#failure gestion
		##to much torque
		if(me.prop_torque.getValue()>50){#overtorque, generate chip
			me.chip.setValue(me.chip.getValue()+(0.1*dt));
			if(me.chip.getValue()>1){
				me.failure_propeller.setValue(1);
				setprop("/sim/messages/copilot", "Torque too high, propeller reductor destroyed");
			}
		}
		
		##torque reverse in flight (when speed is more then 50kts)
		if(me.prop_torque.getValue()>0 and me.power_reverse.getValue()>0 and getprop("velocities/airspeed-kt")>50){#reverse in flight, generate chip
			me.chip.setValue(me.chip.getValue()+(0.1*dt));
			if(me.chip.getValue()>1){
				me.failure_propeller.setValue(1);
				setprop("/sim/messages/copilot", "Torque too high, propeller reductor destroyed");
			}
		}
		
		##to much propeller rpm
		if(me.prop_rpm.getValue()>2700){#to much prop rpm, the blades are flying away !!!
			me.failure_propeller_blade.setValue(1);
			setprop("/sim/messages/copilot", "Too high propeller rpm, some propeller's blades destroyed!!!");
		}
		
		##to much ITT
		if(me.turbine_itt.getValue()>1090){#to much itt, turbine is fusionning !!!
			me.failure_turbine.setValue(1);
			setprop("/sim/messages/copilot", "Too high ITT, turbine destroyed, fire !!!");
		}
	},
	autostart : func {
		##let the engine run
		me.throttle.setValue(0.4);
		me.pitch_lever.setValue(1);
		
		me.turbine_rpm.setValue(27750);
		me.turbine_itt.setValue(680);
		setprop("/consumables/fuel/switch-position",1);
		me.condition.setValue(2);
		
		me.running.setValue(1);
		me.starting.setValue(0);
		me.ignition.setValue(0);
		me.fuel_press.setValue(1);
		
		##switch on the electrical system
		setprop("/controls/switches/battery-click",1);
		setprop("/controls/switches/generator-click",1);
		
		setprop("/sim/alarms/caution-warning",0);
		setprop("/sim/messages/copilot","The engine is started, you now have to switch on radio, lights, and ...");
		
	}
};

var update_engine = func{
	var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;

	engine.update(dt);

    # Request that the update fuction be called again next frame
    settimer(update_engine, 0);
}

var starting_listener = func{
	if(getprop("/instrumentation/starter/serviceable")){
		engine.starting.setBoolValue(1);
	}else{
		engine.starting.setBoolValue(0);
	}
}
setlistener("/instrumentation/starter/serviceable",starting_listener);

var ignition_listener = func{
	if(getprop("/instrumentation/ignition/serviceable")){
		engine.ignition.setBoolValue(1);
	}else{
		engine.ignition.setBoolValue(0);
	}
}
setlistener("/instrumentation/ignition/serviceable",ignition_listener);

var pitch_listener = func{
	if(engine.failure_propeller.getValue()==0 and engine.failure_propeller_blade.getValue()==0){
		engine.pitch.setValue(engine.pitch_lever.getValue());
	}
}
setlistener("/engines/pt6a/propeller-pitch-lever",pitch_listener);


##############failures listeners
var failure_propeller_listener = func{
	if(getprop("/engines/pt6a/failure/propeller")){
		engine.pitch.setBoolValue(0);
	}
}
setlistener("/engines/pt6a/failure/propeller",failure_propeller_listener);

var failure_propeller_blade_listener = func{
	if(getprop("/engines/pt6a/failure/propeller-blade")){
		engine.pitch.setBoolValue(0);
		engine.failure_propeller.setBoolValue(1);
	}
}
setlistener("/engines/pt6a/failure/propeller-blade",failure_propeller_blade_listener);

var failure_turbine_listener = func{
	if(getprop("/engines/pt6a/failure/turbine")){
		engine.running.setBoolValue(0);
	}
}
setlistener("/engines/pt6a/failure/turbine",failure_turbine_listener);

var failure_turbine_thermal_shock_listener = func{
	if(getprop("/engines/pt6a/failure/turbine_thermal_shock")){
		engine.running.setBoolValue(0);
	}
}
setlistener("/engines/pt6a/failure/turbine_thermal_shock",failure_turbine_thermal_shock_listener);
