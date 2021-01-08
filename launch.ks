PARAMETER orbit_alt IS 80000.
PARAMETER pitchover_dir IS V(90, 80, 0).
PARAMETER pitchover_speed IS 50.

RUN ONCE lib.

SAS OFF.
RCS OFF.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

PRINT "Liftoff".
STAGE.
LOCK STEERING TO HEADING(90, 90).
LOCK THROTTLE TO 1.

WAIT UNTIL ship:verticalspeed > pitchover_speed.

PRINT "Pitchover: " + pitchover_dir.
LOCK STEERING TO HEADING(pitchover_dir:x, pitchover_dir:y).
WAIT UNTIL VANG(SHIP:SRFPROGRADE:vector, HEADING(pitchover_dir:x, pitchover_dir:y):VECTOR) < 0.5.

LOCK STEERING TO SHIP:SRFPROGRADE.

PRINT "Gravity turn".
WAIT UNTIL ALT:APOAPSIS > orbit_alt.
UNLOCK THROTTLE.
PRINT "Target apoapsis reached: " + orbit_alt + "m".

RUN boostback.
