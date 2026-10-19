// The stages' motion as functions of their time t, seconds at 60 frames
// per second: off screen a stage draws frame after frame as fast as the
// device can, so its picture follows the frame number, not the clock, and
// every device draws the same frames (2.2).
.pragma library

// 0 to 1 once per period
function cycle(t, period) {
    return (t % period) / period
}
// from, to and back, each way in `half` seconds; eased like InOutSine
function swing(t, from, to, half) {
    var u = (t % (2 * half)) / half
    if (u > 1) u = 2 - u
    return from + (to - from) * (0.5 - 0.5 * Math.cos(Math.PI * u))
}
// the same at an even pace
function bounce(t, from, to, half) {
    var u = (t % (2 * half)) / half
    if (u > 1) u = 2 - u
    return from + (to - from) * u
}
