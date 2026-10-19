// The One Million worker: counts to one million per request in 50 runs of
// 20000, and after each run sends the count, the time the counting itself
// took and a batch of random dots. One million per request, so the worker
// is free between them and the stage can stop.
// The score is the counting time only: before, every million also waited
// for the GUI thread's reply and its 50 messages, and a modulo in the loop
// was most of the work (night audit, 2026-10-19).
WorkerScript.onMessage = function (msg) {
    var c = 0
    for (var o = 0; o < 50; o++) {
        var t = Date.now()
        for (var i = 0; i < 20000; i++)
            c++
        var ms = Date.now() - t
        var xy = []
        for (var k = 0; k < 40; k++)
            xy.push(Math.random(), Math.random())
        WorkerScript.sendMessage({ count: c, ms: ms, lap: msg.lap, xy: xy, done: o === 49 })
    }
}
