parameter target_precision is 0.1.
parameter target_alt is ship:bounds:bottomaltradar.
parameter target_pos is ship:geoposition.
parameter max_vspeed is 20.
parameter max_hspeed is 20.
parameter hspeed_stab is 3.
parameter hover_stab is 10.
parameter delta_t is 0.1.

run hover.
hover_pos(target_precision, target_alt, target_pos, max_vspeed, max_hspeed, hspeed_stab, hover_stab, delta_t).
