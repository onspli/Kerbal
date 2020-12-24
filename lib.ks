
function value_mod {
  parameter d.
  parameter m.

  local r is mod(d, m).
  if r < 0 set r to r + m.
  return r.
}


function value_sgn {
  parameter value.
  if value < 0 return -1.
  if value > 0 return 1.
  return 0.
}

function value_limit {
  parameter val.
  parameter min.
  parameter max.
  if val < min return min.
  if val > max return max.
  return val.
}


function surface_vec {
  parameter vec.
  local west is vcrs(north:vector, up:vector).
  return V(vec * up:vector, vec * north:vector, vec * west).
}

function orig_vector {
  parameter vec.
  return up * V(vec:z, vec:y, vec:x).
}

function grav_acc {
  return -(body:mu / body:radius ^ 2) * up:vector.
}


FUNCTION impact_time {
  LOCAL v IS SHIP:VERTICALSPEED.
  LOCAL h IS ALT:RADAR.
  LOCAL g IS grav_acc():MAG.
  LOCAL t IS (v + SQRT(v^2 + 2 * g * h)) / g.
  PRINT "Est time to impact: " + ROUND(t) + "s".
  LOG "Est time to impact: " + ROUND(t) + "s" TO impact.log.
  RETURN t.
}

FUNCTION impact_lng {
  LOCAL a IS ship:orbit:semimajoraxis.
  LOCAL b IS ship:orbit:semiminoraxis.
  LOCAL e IS ship:orbit:eccentricity.
  LOCAL r IS body:radius.
  LOCAL D IS a^2 * b^2 + r^2 - b^2.

  // noneliptical orbit
  IF e = 0 OR e >= 1 RETURN -1.

  // no intersection of body and orbit
  IF r < a * (1 - e) OR r > a * (1 + e) RETURN -1.

  // compute intersection of body and orbit
  LOCAL imp IS V((r - a) / e, 0, 0).
  SET imp:Y TO SQRT(r^2 - (imp:X + e * a)^2).
  IF SHIP:ORBIT:INCLINATION >= 90 SET imp:Y TO -imp:Y.

  // compute angle between periapsis and impact
  LOCAL ang IS VANG(V(-1,0,0), imp).
  IF imp:Y > 0 SET ang TO -ang.
  SET ang TO ang + SHIP:ORBIT:LAN + SHIP:ORBIT:ARGUMENTOFPERIAPSIS - BODY:ROTATIONANGLE.

  // corect with body rotation estimate
  LOCAL rot IS impact_time() / BODY:ROTATIONPERIOD.
  SET ang TO ang - rot * 360.

  SET ang TO value_mod(ang, 360).
  PRINT "Est impact LNG: " + ROUND(ang, 2).
  PRINT "Ship LNG: " + ROUND(value_mod(ship:geoposition:lng, 360), 2).

  LOG "Est impact LNG: " + ROUND(ang, 2) TO impact.log.
  LOG "Ship LNG: " + ROUND(value_mod(ship:geoposition:lng, 360), 2) TO impact.log.
  RETURN ang.
}
