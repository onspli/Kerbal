parameter vel is V(0,0,0).
run hover.

hover_log_clear().

print "Hovering at velocity " + vel.
until false {
  hover(vel).
}
