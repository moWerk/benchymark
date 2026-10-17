<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1">
<context>
    <name></name>
    <message id="id-stage-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="28"/>
        <source>Benchy light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="30"/>
        <source>Two 3DBenchy wireframes turning, each drawn ten times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="32"/>
        <source>Benchy heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="34"/>
        <source>Six boats, each drawn twenty times: 120 wireframes every frame, much more geometry than the picture shows.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-glow">
        <location filename="../qml/pages/MainPage.qml" line="36"/>
        <source>Benchy glow</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-glow">
        <location filename="../qml/pages/MainPage.qml" line="38"/>
        <source>A Benchy with a pulsing golden halo: a blur over the whole screen every frame, the cost of soft effects.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="40"/>
        <source>Shader light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="42"/>
        <source>A drifting noise field computed for every pixel: GPU arithmetic that grows with the screen size.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="44"/>
        <source>Shader heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="46"/>
        <source>The same idea warped twice over, about thirty noise lookups per pixel: the heaviest GPU load here.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="48"/>
        <source>Overdraw</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="50"/>
        <source>72 large translucent squares stacked and turning: every pixel is blended many times, raw fill rate.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cascade">
        <location filename="../qml/pages/MainPage.qml" line="52"/>
        <source>Cascade</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cascade">
        <location filename="../qml/pages/MainPage.qml" line="54"/>
        <source>A thousand rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-icons">
        <location filename="../qml/pages/MainPage.qml" line="56"/>
        <source>Icon storm</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-icons">
        <location filename="../qml/pages/MainPage.qml" line="58"/>
        <source>Rockets and flashes on spiral arms, each icon drawn three times: many small images moving every frame.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-scale">
        <location filename="../qml/pages/MainPage.qml" line="60"/>
        <source>Text scale</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-scale">
        <location filename="../qml/pages/MainPage.qml" line="62"/>
        <source>Numbers growing and shrinking by a scale transform: text drawn once and only resized, the cheap way.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-reraster">
        <location filename="../qml/pages/MainPage.qml" line="64"/>
        <source>Text reraster</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-reraster">
        <location filename="../qml/pages/MainPage.qml" line="66"/>
        <source>The same picture made by changing the font size, so every glyph is drawn anew each frame: what animated text size costs.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu">
        <location filename="../qml/pages/MainPage.qml" line="68"/>
        <location filename="../qml/stages/CpuPrime.qml" line="22"/>
        <source>CPU prime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu">
        <location filename="../qml/pages/MainPage.qml" line="70"/>
        <source>All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="72"/>
        <location filename="../qml/stages/CpuPrimeSingle.qml" line="11"/>
        <source>CPU single core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="74"/>
        <source>The same prime counting on one core only: next to the all core figure it shows what a single core does.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-memory">
        <location filename="../qml/pages/MainPage.qml" line="76"/>
        <location filename="../qml/stages/Memory.qml" line="112"/>
        <source>Memory throughput</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-memory">
        <location filename="../qml/pages/MainPage.qml" line="78"/>
        <source>Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-million">
        <location filename="../qml/pages/MainPage.qml" line="80"/>
        <location filename="../qml/stages/OneMillion.qml" line="84"/>
        <source>One million</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-million">
        <location filename="../qml/pages/MainPage.qml" line="82"/>
        <source>JavaScript counts to one million, over and over: how fast the app&apos;s script engine runs a plain loop.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage">
        <location filename="../qml/pages/MainPage.qml" line="85"/>
        <source>Storage performance</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-storage">
        <location filename="../qml/pages/MainPage.qml" line="87"/>
        <source>Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-loop">
        <location filename="../qml/pages/MainPage.qml" line="448"/>
        <source>Run in loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-once">
        <location filename="../qml/pages/MainPage.qml" line="450"/>
        <source>Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-start">
        <location filename="../qml/pages/MainPage.qml" line="468"/>
        <source>Start</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-next">
        <location filename="../qml/pages/MainPage.qml" line="528"/>
        <source>Next: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tap-to-stop">
        <location filename="../qml/pages/MainPage.qml" line="576"/>
        <source>Tap to stop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-loop-short">
        <location filename="../qml/pages/MainPage.qml" line="623"/>
        <source>loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-stage">
        <location filename="../qml/pages/MainPage.qml" line="642"/>
        <source>Stage</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-avg">
        <location filename="../qml/pages/MainPage.qml" line="650"/>
        <source>avg</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-min">
        <location filename="../qml/pages/MainPage.qml" line="657"/>
        <source>min</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-worst">
        <location filename="../qml/pages/MainPage.qml" line="664"/>
        <source>worst ms</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-direct">
        <location filename="../qml/pages/MainPage.qml" line="705"/>
        <source>* without O_DIRECT: the read may come from the cache</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-temperature">
        <location filename="../qml/pages/MainPage.qml" line="720"/>
        <source>Temperature</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-image">
        <location filename="../qml/pages/MainPage.qml" line="781"/>
        <source>Share image</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-json">
        <location filename="../qml/pages/MainPage.qml" line="786"/>
        <source>Share JSON</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-back">
        <location filename="../qml/pages/MainPage.qml" line="793"/>
        <source>Back</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-results">
        <location filename="../qml/pages/MainPage.qml" line="804"/>
        <source>Share results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-peak">
        <location filename="../qml/pages/MainPage.qml" line="838"/>
        <source>peak</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-writing">
        <location filename="../qml/stages/Storage.qml" line="72"/>
        <location filename="../qml/stages/Storage.qml" line="80"/>
        <source>Writing</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-reading">
        <location filename="../qml/stages/Storage.qml" line="72"/>
        <location filename="../qml/stages/Storage.qml" line="82"/>
        <source>Reading</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage-rw">
        <location filename="../qml/stages/Storage.qml" line="87"/>
        <location filename="../qml/stages/Storage.qml" line="92"/>
        <source>Storage R/W</source>
        <translation type="unfinished"></translation>
    </message>
</context>
</TS>
