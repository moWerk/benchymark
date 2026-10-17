// The One Million worker: counts to one million per request and sends the
// count and a batch of random dots after every 20000. One million per
// request, so the worker is free between them and the stage can stop.
WorkerScript.onMessage = function (msg) {
    for (var i = 1; i <= 1000000; i++) {
        if (i % 20000 === 0) {
            var xy = []
            for (var k = 0; k < 40; k++)
                xy.push(Math.random(), Math.random())
            WorkerScript.sendMessage({ count: i, lap: msg.lap, xy: xy, done: i === 1000000 })
        }
    }
}
