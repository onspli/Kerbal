parameter launch_alt is 1000.
run hover.

deletepath(land.log).

// Altitude after burn with constant acceleration, when velocity reaches target_vel.
// Ship is burning retrograde, the retrograde vector is changing, the thrust is not constant and
// we completely ignore drag. But we just want solid approximation.
// Lets pretend we first burn in the current retrograde direction until we kill the horizontal velocity,
// then we burn in up direction. It is acutally less efficient than burning retrograde all he time,
// so it should give lower bound on the final altitude after burn, and that is exactly what we want.
// Also the drag can only help us.
function alt_after_burn {
  parameter alt.
  parameter target_vel is 0.
  parameter throt is 1.
  log "alt: " + alt + ", target_vel: " + target_vel + ", thro: " + throt to land.log.

  // first burn in current diraction, until we kill horizontal velocity.
  local vel1 is ship:velocity:surface.
  local vel1srfc is surface_vec(vel1).
  local vacc1 is throt * (ship:availablethrust / ship:mass) * ship:facing:vector * up:vector - grav_acc():mag.
  if vacc1 < 0 return alt.
  local hacc1 is throt * (ship:availablethrust / ship:mass) * vectorexclude(up:vector, ship:facing:vector):mag.
  local dur1 is vectorexclude(up:vector, vel1):mag / hacc1.
  local alt1 is alt + vel1 * up:vector * dur1 + vacc1 * dur1 ^ 2 * 0.5.
  log "alt1: " + alt1 + ", vacc1: " + vacc1 + ", hacc1: " + hacc1 + ", vel1: " + vel1srfc + ", dur1: " + dur1 to land.log.


  // second burn with ship facing up
  local vel2 is vel1 * up:vector + dur1 * vacc1.
  local vacc2 is throt * (ship:availablethrust / ship:mass) - grav_acc():mag.
  local dur2 is -(vel2 - target_vel) / vacc2.
  local alt2 is alt1 + vel2 * dur2 + vacc2 * dur2 ^ 2 * 0.5.
  log "alt2: " + alt2 + ", vacc2: " + vacc2 + ", vel2: " + vel2 + ", dur2: " + dur2 to land.log.

  // panic
  if vacc2 < 0 return -100.
  // heading up
  if vel1srfc:x > 0 return alt.

  print "Expected altitude: " + alt2.
  return alt2.
}

function alter_throttle {
  parameter alt.
  parameter target_alt.
  parameter target_vel is 0.

  local vel is -ship:verticalspeed.
  local sacc is ship:facing:vector * up:vector * ship:availablethrust / ship:mass.
  local gacc is grav_acc():mag.
  local delta_vel is vel + target_vel.
  // time to panic
  if sacc <= 0 return 0.
  if target_alt - alt >= 0 return 0.
  return gacc / sacc + (delta_vel - 2 * vel) * delta_vel / (2 * sacc * (target_alt - alt)).
}

function launch {
  parameter alt.
  lock throttle to 1.0.
  //lock steering to up:vector.
  stage.

  wait until ship:orbit:apoapsis > alt.
  unlock throttle.
  unlock steering.
}

function landing_burn {
  parameter target_alt is 50.
  parameter final_alt is 0.5.
  parameter target_vel is -1.

  // wait until the ship is falling down
  wait until ship:verticalspeed < -5.
  lock steering to ship:srfretrograde:vector.

  // wait for landing burn ignition
  local ship_bounds is ship:bounds.
  local prev_alt is alt_after_burn(ship_bounds:bottomaltradar, target_vel).
  until false {
    local alt is alt_after_burn(ship_bounds:bottomaltradar, target_vel).
    local delta_alt is alt - prev_alt.
    set prev_alt to alt.
    if alt + delta_alt < target_alt {
      break.
    }
    wait 0.1.
  }
  log "Landing burn started" to land.log.
  print "Landing burn started".
  lock throttle to 1.0.

  // finetune throttle to final altitude
  until ship_bounds:bottomaltradar < final_alt {
    alt_after_burn(ship_bounds:bottomaltradar, target_vel, throttle).
    lock throttle to value_limit(alter_throttle(ship_bounds:bottomaltradar, final_alt, target_vel), 0, 1).
    if ship:verticalspeed > target_vel lock steering to up:vector.
    wait 0.1.
  }

  // shut down engines
  set ship:control:pilotmainthrottle to 0.
  unlock throttle.
  unlock steering.
  print "Landing burn completed".
}

launch(launch_alt).

landing_burn(20).
