# ===========================
# Immatriculation by Zakharov
# Tuned by Torsten Dreyer
# ===========================

var registrationDialog = gui.Dialog.new("/sim/gui/dialogs/pc6/status/dialog",
				  "Aircraft/PC-6/Dialogs/registration.xml");

var l = setlistener("/sim/signals/fdm-initialized", func {
  var callsign = props.globals.getNode("/sim/multiplay/callsign",1).getValue();
  if( callsign == nil or callsign == "callsign" )
    callsign = "F-JEEP";
  props.globals.initNode( "/sim/multiplay/generic/string[0]", callsign, "STRING" );
  removelistener(l);
});
