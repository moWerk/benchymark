// The One Million worker: counts in stretches of about 50 ms and after each
// sends the steps, the time the counting took and a batch of random dots,
// without waiting for an answer. A request counts for about a quarter of a
// second, so the stage can stop between two requests.
// The worker stays busy (2.3): until 2.2 it counted one million, then waited
// for the GUI thread, about a fifth of the time busy, and the scheduler left
// it on a little core (Pro1-X: 97 M/s there, 188 M/s on a big core).
// The score is the counting time only; a stretch of 50 ms keeps the 1 ms
// clock to about 2 %. The count starts at 0 every stretch, so it stays a
// small integer.
WorkerScript.onMessage = function (msg) {
    var end = Date.now() + 250
    var now = 0
    do {
        var t = Date.now()
        var c = 0
        do {
            for (var i = 0; i < 20000; i++)
                c++
            now = Date.now()
        } while (now - t < 50)
        var xy = []
        for (var k = 0; k < 200; k++)
            xy.push(Math.random(), Math.random())
        WorkerScript.sendMessage({ steps: c, ms: now - t, xy: xy, done: now >= end })
    } while (now < end)
}
