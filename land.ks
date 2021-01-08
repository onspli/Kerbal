PARAMETER target_lng IS -1.
//deletepath(land.log).
RUN ONCE lib.

// Altitude after burn with constant acceleration, when velocity reaches target_vel.
// Ship is burning retrograde, the retrograde vector is changing, the thrust is not constant and
// we completely ignore drag. But we just want solid approximation.
// Lets pretend we first burn in the current retrograde direction until we kill the horizontal velocity,
// then we burn in up direction. It is acutally less efficient than burning retrograde all he time,
// so it should give lower bound on the final altitude after burn, and that is exactly what we want.
// Also the drag can only help us.
function pos_after_burn {
  parameter alt.
  parameter target_vel is 0.
  parameter throt is 1.
  //log "alt: " + alt + ", target_vel: " + target_vel + ", thro: " + throt to land.log.

  local ilng is impact_lng().
  // panic - no fuel
  if ship:availablethrust = 0 return V(-100, ilng, 0).

  // first burn in current diraction, until we kill horizontal velocity.
  local vel1 is ship:velocity:surface.
  local vel1srfc is surface_vec(vel1).
  if vel1srfc:x > 0 return V(alt, ilng, 0). // heading up
  local vacc1koef is ship:facing:vector * up:vector.
  if vacc1koef < 0 return V(alt, ilng, 0). // facing down

  local vacc1 is throt * (ship:availablethrust / ship:mass) * vacc1koef - grav_acc():mag.
  local hacc1 is throt * (ship:availablethrust / ship:mass) * vectorexclude(up:vector, ship:facing:vector).
  local dur1 is vectorexclude(up:vector, vel1):mag / hacc1:mag.
  local alt1 is alt + vel1 * up:vector * dur1 + vacc1 * dur1 ^ 2 * 0.5.
  //log "alt1: " + alt1 + ", vacc1: " + vacc1 + ", hacc1: " + hacc1:mag + ", vel1: " + vel1srfc + ", dur1: " + dur1 to land.log.

  // second burn with ship facing up
  local vel2 is vel1 * up:vector + dur1 * vacc1.
  local vacc2 is throt * (ship:availablethrust / ship:mass) - grav_acc():mag.
  local dur2 is -(vel2 - target_vel) / vacc2.
  local alt2 is alt1 + vel2 * dur2 + vacc2 * dur2 ^ 2 * 0.5.
  //log "alt2: " + alt2 + ", vacc2: " + vacc2 + ", vel2: " + vel2 + ", dur2: " + dur2 to land.log.

  // panic - we dont have enough thrust to fight the gravity.
  if vacc2 < 0 return V(-100, ilng, 0).

  print "Est ALT: " + alt2 + "m".
  return V(alt2, ilng, 0).
}

function alter_throttle {
  parameter alt.
  parameter target_alt.
  parameter target_vel is 0.

  local vel is -ship:verticalspeed.
  local sacc is ship:facing:vector * up:vector * ship:availablethrust / ship:mass.
  local gacc is grav_acc():mag.
  local delta_vel is vel + target_vel.
  // panic - we dont have enough thrust to fight the gravity.
  if sacc = 0 or sacc <= gacc return 1.
  // we reached target altitude
  if alt - target_alt <= 0 return 0.
  return gacc / sacc + (delta_vel - 2 * vel) * delta_vel / (2 * sacc * (target_alt - alt)).
}

function landing_burn {
  parameter target_alt is 50.
  parameter final_alt is 0.5.
  parameter target_vel is -1.

  // wait until the ship is falling down
  wait until ship:verticalspeed < -5.
  lock steering to ship:srfretrograde:vector.
  airbrakes_extended(true).

  // wait for landing burn ignition
  local ship_bounds is ship:bounds.
  local prev_alt is ship_bounds:bottomaltradar.
  until false {
    local pos is pos_after_burn(ship_bounds:bottomaltradar, target_vel).
    local alt is pos:x.
    local delta_alt is alt - prev_alt.
    set prev_alt to alt.
    if alt + delta_alt < target_alt {
      break.
    }
    wait 0.1.
  }
  //log "Landing burn started" to land.log.
  lock steering to ship:srfretrograde:vector.
  print "Landing burn started".
  lock throttle to 1.0.

  // finetune throttle to final altitude
  until ship_bounds:bottomaltradar < final_alt {
    pos_after_burn(ship_bounds:bottomaltradar, target_vel, throttle).
    lock throttle to value_limit(alter_throttle(ship_bounds:bottomaltradar, final_alt, target_vel), 0, 1).
    if ship:verticalspeed > target_vel lock steering to up:vector.
    wait 0.1.
  }

  // shut down engines
  set ship:control:pilotmainthrottle to 0.
  unlock throttle.
  unlock steering.
  airbrakes_extended(false).
  print "Landing burn completed".
}

landing_burn(20).
