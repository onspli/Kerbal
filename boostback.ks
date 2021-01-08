PARAMETER target_lng IS 284.
PARAMETER flipover_dir IS V(90, 180, 0).

RUN ONCE lib.

RUN setdistances(150000).

LOCK STEERING TO SHIP:PROGRADE.
WAIT UNTIL SHIP:VERTICALSPEED < 400.
STAGE.


WAIT UNTIL SHIP:VERTICALSPEED < 100.
PRINT "Flipover: " + flipover_dir.
LOCK STEERING TO HEADING(flipover_dir:X, flipover_dir:Y).
RCS ON.
WAIT UNTIL VANG(SHIP:FACING:VECTOR, HEADING(flipover_dir:X, flipover_dir:Y):VECTOR) < 5 OR SHIP:VERTICALSPEED < 50.
RCS OFF.

PRINT "Boostback, lng: " + target_lng.
LOCK THROTTLE TO 1.
deletepath(impact.log).
UNTIL impact_lng() > target_lng LOCK STEERING TO HEADING(flipover_dir:X, flipover_dir:Y).
UNTIL impact_lng() <= target_lng LOCK STEERING TO HEADING(flipover_dir:X, flipover_dir:Y).
UNLOCK THROTTLE.
UNLOCK STEERING.

PRINT "Landing".
RUN LAND(target_lng).

RUN setdistances.
