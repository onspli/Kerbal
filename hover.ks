
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

function hover_log {
  parameter str.
  log str to hover.log.
}

function hover_log_clear {
  deletepath(hover.log).
}

function moving_avarage_update {
  parameter value.
  parameter vlist.

  vlist:remove(vlist:length - 1).
  vlist:remove(0).
  vlist:add(value).

  local i is 0.
  local res is 0.
  until i >= vlist:length {
    if i = 0 set res to vlist[i].
    else set res to res + vlist[i].
    set i to i + 1.
  }
  set res to res / vlist:length.

  vlist:add(res).
  return vlist.
}

function moving_avarage {
  parameter vlist.
  return vlist[vlist:length - 1].
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

function hover {
  parameter target_vel is V(0,0,0).
  parameter stabilization is 5.
  parameter delta_t is 0.1.

  hover_log("-- hover --").

  local vel is surface_vec(ship:velocity:surface).
  local target_acc is (target_vel - vel) / delta_t.

  hover_log("target_vel: " + target_vel:mag + ", " + target_vel).
  hover_log("target_acc: " + target_acc:mag + ", " + target_acc).

  local gacc is surface_vec(grav_acc()).
  local target_ship_acc is target_acc - gacc.
  hover_log("target_shi_acc: " + target_ship_acc:mag + ", " + target_ship_acc).

  local up_srfc is surface_vec(up:vector).
  local facing_srfc is surface_vec(ship:facing:vector).

  local throt is value_limit(throttle, 0, 1).
  local ship_max_acc is ship:availablethrust / ship:mass.
  if ship_max_acc > 0 set throt to value_limit(target_ship_acc * up_srfc / ship_max_acc, 0.05, 1).
  lock throttle to throt.
  set ship:control:pilotmainthrottle to throt.

  local steer is target_ship_acc:vec.
  local hacc is vectorexclude(up_srfc, steer):mag.
  local vacc is steer * up_srfc.

  // keep the pointy end of vessel up
  local min_vacc is hacc * stabilization - gacc:x.
  if steer:x < min_vacc set steer:x to min_vacc.
  lock steering to orig_vector(steer).

  //set hover_acc_draw to vecdraw(V(0,0,0), orig_vector(target_ship_acc), green, "", 1, true).
  //set hover_steer_draw to vecdraw(V(0,0,0), orig_vector(steer), blue, "", 1, true).
}

function hover_pos {
  parameter target_precision is 0.1.
  parameter target_alt is ship:bounds:bottomaltradar.
  parameter target_pos is ship:geoposition.
  parameter max_vspeed is 20.
  parameter max_hspeed is 20.
  parameter hspeed_stab is 3.
  parameter hover_stab is 10.
  parameter delta_t is 0.1.

  hover_log_clear().

  local ship_bounds is ship:bounds.
  local dist is V(1,0,0).
  until dist:mag < target_precision {
    local delta_alt is target_alt - ship_bounds:bottomaltradar.
    set dist to vectorexclude(up:vector, target_pos:position).
    set dist:mag to min(dist:mag * hspeed_stab / max_hspeed, dist:mag * dist:mag * hspeed_stab / max_hspeed).
    if dist:mag > max_hspeed set dist:mag to max_hspeed.

    set dist to surface_vec(dist).
    set dist:x to delta_alt.
    if abs(dist:x) > max_vspeed set dist:x to value_sgn(dist:x) * max_vspeed.
    //set dist_draw to vecdraw(V(0,0,0) + ship:facing:vector * 10, orig_vector(dist), blue, "", 1, true).
    set target_draw to vecdraw(V(0,0,0), target_pos:position, yellow, "", 1, true).
    hover(dist, hover_stab, delta_t).
    wait delta_t.
  }

}

function hover_land {
  parameter target_precision is 0.1.
  parameter max_vspeed is 10.
  parameter hover_stab is 10.
  parameter delta_t is 0.1.

  hover_log_clear().

  local ship_bounds is ship:bounds.
  local dist is V(1,0,0).
  until dist:mag < target_precision {
    local delta_alt is 0 - ship_bounds:bottomaltradar.
    set dist:x to delta_alt.
    if abs(dist:x) > max_vspeed set dist:x to value_sgn(dist:x) * max_vspeed.
    hover(dist, hover_stab, delta_t).
    wait delta_t.
  }

  set ship:control:pilotmainthrottle to 0.

}

clearvecdraws().
