parameter vel is V(0,0,0).
parameter stabilization is 5.
parameter delta_t is 0.1.

run hover.

hover_log_clear().

print "Hovering at velocity " + vel.
until false {
  hover(vel, stabilization, delta_t).
  wait delta_t.
}
