# Damped G value - starts at 1.
GDamped = 1.0;

blackout = func {
    GCurrent = getprop("/accelerations/pilot-g[0]");
    GMin = getprop("/accelerations/pilot-gmin[0]");
    GMax = getprop("/accelerations/pilot-gmax[0]");
    
    if (GCurrent == nil) { GCurrent = 1.0; }
    if (GMin == nil) { GMin = 1.0; }
    if (GMax == nil) { GMax = 1.0; }
    
    # Updated the GDamped using a low-pass filter.
    # Blackout onsets and clears slower than redout
    # so we use a different filter in each case.
    if (GDamped < 0)
    {
        GDamped = GDamped * 0.80 + GCurrent * 0.20;
    }
    else
    {
        GDamped = GDamped * 0.90 + GCurrent * 0.10;
    }

    if (GDamped > 2.5) 
    {
        setprop("/sim/rendering/redout/red",0);
        setprop("/sim/rendering/redout/alpha",(GDamped/7));
    }
    elsif (GDamped < -1) 
    {
        setprop("/sim/rendering/redout/red",1);
        setprop("/sim/rendering/redout/alpha",(GDamped/7)*-1);
    }
    else 
    {
        setprop("/sim/rendering/redout/alpha",0);
    }
}

setlistener("/accelerations/pilot-g", blackout);
