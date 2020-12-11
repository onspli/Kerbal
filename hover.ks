
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

// time of last hoverloop
global hover_t is 0.
// last velocity.
global hover_vel is V(0,0,0).
// last facing
global hover_facing is V(1,0,0).

function hover {
  parameter target_vel is V(0,0,0).

  hover_log("-- hover loop --").

  local delta_t is time:seconds - hover_t.
  set hover_t to time:seconds.

  local vel is surface_vec(ship:velocity:surface).
  local acc is (vel - hover_vel) / delta_t.
  set hover_vel to vel.
  local target_acc is (target_vel - vel) / delta_t.

  local throt is value_limit(throttle, 0, 1).
  local max_acc is (ship:availablethrust / ship:mass).

  hover_log("delta_t: " + delta_t).
  //  hover_log("acc: " + acc:mag + ", " + acc).
  //  hover_log("throt: " + throt).
  //  hover_log("max acc: " + max_acc).

  local facing is surface_vec(ship:facing:vector):normalized.
  local sacc is throt * max_acc * (facing + hover_facing):normalized.
  local gacc is acc - sacc.
  local target_sacc is target_acc - gacc.

  set hover_facing to surface_vec(ship:facing:vector):normalized.
  if max_acc > 0 {
    set throt to value_limit(target_sacc * hover_facing / max_acc, 0.1, 1).
  }
  lock throttle to throt.
  set ship:control:pilotmainthrottle to throt.

  local steer is target_sacc:normalized.
  // keep the pointy end of vessel up
  local min_steer_x is 0.5.
  if steer:x < min_steer_x set steer:x to min_steer_x.

  hover_log("gacc: " + gacc:mag + ", " + gacc).
  //  hover_log("facing: " + facing).
  //  hover_log("ship acc: "+ sacc:mag + ", "  + sacc).
  //  hover_log("target ship acc: " + target_sacc).
  //  hover_log("throt: " + throt).
  //  hover_log("steer: " + steer).

  set hover_acc_draw to vecdraw(V(0,0,0), orig_vector(target_sacc), green, "", 1, true).
  set hover_steer_draw to vecdraw(V(0,0,0), orig_vector(steer)*5, blue, "", 1, true).
  lock steering to orig_vector(steer).
  wait 0.05.
}

function hover_land {
  print "Landing".
  legs on.
  hover_alt(0, 0).
  unlock throttle.
  set ship:control:pilotmainthrottle to 0.
  print "Landed".
}

function hover_alt {
  parameter alt.
  parameter dur.

  hover_log_clear().

  local ship_bounds is ship:bounds.
  print "Changing alt to " + alt + "m".
  until abs(ship_bounds:bottomaltradar - alt) < 0.5 {
    hover(alt - ship_bounds:bottomaltradar).
  }

  print "Hovering at " + alt + "m for " + dur +"s".
  set t0 to time:seconds.
  until time:seconds - t0 > dur {
    hover(alt - ship_bounds:bottomaltradar).
  }
  unlock throttle.
  print "Hovering finished".
}
