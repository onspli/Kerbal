// vertical acceleration (pointing up)
function ship_vacc {
  parameter delta_t.

  local t0 is time:seconds.
  local vel0 is ship:verticalspeed.
  wait delta_t.
  local acc is (ship:verticalspeed - vel0) / (time:seconds - t0).
  return acc.
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

function hover_target_acc {
  parameter delta_alt.
  parameter delta_t.

  local vel is ship:verticalspeed.
  local target_vel is value_sgn(delta_alt) * value_limit(abs(delta_alt), 0.05, 10).
  local target_acc is (target_vel - vel) / delta_t.
  hover_log("vel: " + vel).
  hover_log("target vel: " + target_vel).
  hover_log("target acc: " + target_acc).
  hover_log("delta_t: " + delta_t).

  return target_acc.
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

  local res is 0.
  for val in vlist set res to res + val.
  set res to res / vlist:length.

  vlist:add(res).
  return vlist.
}

function moving_avarage {
  parameter vlist.
  return vlist[vlist:length - 1].
}

global hover_koef is list(0.1, 0.1, 0.1).
global hover_const is list(0, 0, 0).
global hover_gacc is list(0, 0).
global hover_delta_t is list(0.1, 0.1).
global hover_t is 0.
function hover {
  parameter delta_alt.

  // we cannot ever cut off throttle, because thrust is used for computing gforce
  local throt_min is 0.01.

  hover_log("-- hover loop --").

  local acc is ship_vacc(0.1).
  local throt is value_limit(throttle, 0, 1).
  local ship_acc is throt * (ship:availablethrust / ship:mass) * vdot(up:vector, ship:facing:vector).

  hover_log("acc: " + acc).
  hover_log("throt: " + throt).
  hover_log("ship acc: " + ship_acc).

  if throt >= throt_min {
    set hover_gacc to moving_avarage_update(acc - ship_acc, hover_gacc).
  }
  local gacc is moving_avarage(hover_gacc).
  hover_log("gacc: " + gacc).


  if throt >= throt_min and abs(acc - gacc) > 0 {
    set hover_koef to moving_avarage_update(throt / (acc - gacc), hover_koef).
    set hover_const to moving_avarage_update(- moving_avarage(hover_koef) * gacc, hover_const).
  }
  local koef is moving_avarage(hover_koef).
  local const is moving_avarage(hover_const).

  hover_log("koef: " + koef).
  hover_log("const: " + const).

  local delta_t is time:seconds - hover_t.
  set hover_t to time:seconds.
  local target_acc is 0.
  if delta_t < 1 {
    set hover_delta_t to moving_avarage_update(delta_t, hover_delta_t).
    set target_acc to hover_target_acc(delta_alt, moving_avarage(hover_delta_t)).
  }

  set throt to value_limit(koef * target_acc + const, throt_min, 1).
  hover_log("throt: " + throt).
  hover_log("predicted acc: " + ((throt - const) / koef)).
  lock throttle to throt.
}

function hover_land {
  print "Landing".
  legs on.
  hover_alt(0, 0).
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
  print "Hovering finished".
}
