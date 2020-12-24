PARAMETER orbit_alt IS 80000.
PARAMETER pitchover_dir IS V(90, 75, 0).
PARAMETER pitchover_speed IS 50.
PARAMETER flipover_dir IS V(90, 150, 0).

RUN ONCE lib.

SAS OFF.
RCS OFF.

PRINT "Liftoff".
STAGE.
LOCK STEERING TO HEADING(90, 90).
LOCK THROTTLE TO 1.

WAIT UNTIL ship:verticalspeed > pitchover_speed.

PRINT "Pitchover".
LOCK STEERING TO HEADING(pitchover_dir:x, pitchover_dir:y).
WAIT UNTIL VANG(SHIP:SRFPROGRADE:vector, HEADING(pitchover_dir:x, pitchover_dir:y):VECTOR) < 0.5.

LOCK STEERING TO SHIP:SRFPROGRADE.

PRINT "Gravity turn".
WAIT UNTIL ALT:APOAPSIS > orbit_alt.
UNLOCK THROTTLE.
PRINT "Separation".

WAIT UNTIL SHIP:VERTICALSPEED < 100.
PRINT "Flipover".
LOCK STEERING TO HEADING(flipover_dir:X, flipover_dir:Y).
RCS ON.
WAIT UNTIL VANG(SHIP:FACING:VECTOR, HEADING(flipover_dir:X, flipover_dir:Y):VECTOR) < 5.
RCS OFF.

PRINT "Boostback".
LOCK THROTTLE TO 1.
deletepath(impact.log).
WAIT UNTIL impact_lng() < 285.
UNLOCK THROTTLE.
UNLOCK STEERING.

PRINT "Landing".
RUN LAND.
