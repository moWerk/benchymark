<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1">
<context>
    <name></name>
    <message id="id-stage-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="114"/>
        <source>Benchy light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="116"/>
        <source>Two 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. Scores boats per second.</source>
        <oldsource>Two 3DBenchy wireframes turning, each drawn ten times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="118"/>
        <source>Boats drawn per second, two large ones on screen</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="120"/>
        <source>Benchy heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="122"/>
        <source>Six boats, each drawn many times: much more geometry than the picture shows. Scores boats per second.</source>
        <oldsource>Six boats, each drawn twenty times: 120 wireframes every frame, much more geometry than the picture shows.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="124"/>
        <source>Boats drawn per second, six smaller ones on screen</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-glow">
        <location filename="../qml/pages/MainPage.qml" line="126"/>
        <source>Benchy glow</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-glow">
        <location filename="../qml/pages/MainPage.qml" line="128"/>
        <source>A Benchy with a pulsing golden halo, the glow stacked several times: a blur over the whole picture each, the cost of soft effects. Scores megapixels per second.</source>
        <oldsource>A Benchy with a pulsing golden halo: a blur over the whole screen every frame, the cost of soft effects.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-glow">
        <location filename="../qml/pages/MainPage.qml" line="130"/>
        <source>Megapixels blurred per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="132"/>
        <source>Shader light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="134"/>
        <source>A drifting noise field computed for every pixel, several times over: GPU arithmetic. Scores megapixels per second.</source>
        <oldsource>A drifting noise field computed for every pixel: GPU arithmetic that grows with the screen size.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="136"/>
        <source>Megapixels of noise field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="138"/>
        <source>Shader heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="140"/>
        <source>The same idea warped twice over, about thirty noise lookups per pixel and field: the heaviest GPU arithmetic here. Scores megapixels per second.</source>
        <oldsource>The same idea warped twice over, about thirty noise lookups per pixel: the heaviest GPU load here.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="142"/>
        <source>Megapixels of warped field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="145"/>
        <source>Table from UBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="147"/>
        <source>Every pixel walks a 16 KB table, each index taken from the entry before, here from a uniform buffer (UBO). Scores million table reads per second. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="149"/>
        <source>Million table reads per second from a uniform buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="151"/>
        <source>Table from SSBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="153"/>
        <source>The same table walk from a shader storage buffer (SSBO). Needs OpenGL ES 3.1 and a driver that allows them in fragment shaders.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="155"/>
        <source>Million table reads per second from a storage buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="157"/>
        <source>Table from texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="159"/>
        <source>The same table walk from a float texture, the classic way and the baseline for the two buffers. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="161"/>
        <source>Million table reads per second from a texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="163"/>
        <source>Overdraw</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="165"/>
        <source>Large translucent squares stacked and turning: every pixel is blended many times, raw fill rate. Scores layers per second.</source>
        <oldsource>72 large translucent squares stacked and turning: every pixel is blended many times, raw fill rate.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="167"/>
        <source>Translucent layers blended per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cascade">
        <location filename="../qml/pages/MainPage.qml" line="169"/>
        <source>Cascade</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cascade">
        <location filename="../qml/pages/MainPage.qml" line="171"/>
        <source>Thousands of rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents. Scores squares per second.</source>
        <oldsource>A thousand rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cascade">
        <location filename="../qml/pages/MainPage.qml" line="173"/>
        <source>Squares moved per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-icons">
        <location filename="../qml/pages/MainPage.qml" line="175"/>
        <source>Icon storm</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-icons">
        <location filename="../qml/pages/MainPage.qml" line="177"/>
        <source>Rockets and flashes on spiral arms, stacked: many small images moving every frame. Scores icons per second.</source>
        <oldsource>Rockets and flashes on spiral arms, each icon drawn three times: many small images moving every frame.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-icons">
        <location filename="../qml/pages/MainPage.qml" line="179"/>
        <source>Icons drawn per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-scale">
        <location filename="../qml/pages/MainPage.qml" line="181"/>
        <source>Text scale</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-scale">
        <location filename="../qml/pages/MainPage.qml" line="183"/>
        <source>Numbers growing and shrinking by a scale transform: text drawn once and only resized, the cheap way. Scores texts per second.</source>
        <oldsource>Numbers growing and shrinking by a scale transform: text drawn once and only resized, the cheap way.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-scale">
        <location filename="../qml/pages/MainPage.qml" line="185"/>
        <source>Texts scaled per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-reraster">
        <location filename="../qml/pages/MainPage.qml" line="187"/>
        <source>Text reraster</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-reraster">
        <location filename="../qml/pages/MainPage.qml" line="189"/>
        <source>The same picture made by changing the font size, so every glyph is drawn anew each frame: what animated text size costs. Scores texts per second.</source>
        <oldsource>The same picture made by changing the font size, so every glyph is drawn anew each frame: what animated text size costs.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-reraster">
        <location filename="../qml/pages/MainPage.qml" line="191"/>
        <source>Texts redrawn per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu">
        <location filename="../qml/pages/MainPage.qml" line="193"/>
        <location filename="../qml/stages/CpuPrime.qml" line="22"/>
        <source>CPU prime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu">
        <location filename="../qml/pages/MainPage.qml" line="195"/>
        <source>All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu">
        <location filename="../qml/pages/MainPage.qml" line="197"/>
        <source>Prime counts per second on all cores</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="199"/>
        <location filename="../qml/stages/CpuPrimeSingle.qml" line="11"/>
        <source>CPU single core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="201"/>
        <source>The same prime counting on one core only: next to the all core figure it shows what a single core does.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="203"/>
        <source>Prime counts per second on one core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-memory">
        <location filename="../qml/pages/MainPage.qml" line="205"/>
        <location filename="../qml/stages/Memory.qml" line="120"/>
        <source>Memory throughput</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-memory">
        <location filename="../qml/pages/MainPage.qml" line="207"/>
        <source>Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-memory">
        <location filename="../qml/pages/MainPage.qml" line="209"/>
        <source>Megabytes copied per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-million">
        <location filename="../qml/pages/MainPage.qml" line="211"/>
        <location filename="../qml/stages/OneMillion.qml" line="91"/>
        <source>One million</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-million">
        <location filename="../qml/pages/MainPage.qml" line="213"/>
        <source>JavaScript counts to one million, over and over: how fast the app&apos;s script engine runs a plain loop.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-million">
        <location filename="../qml/pages/MainPage.qml" line="215"/>
        <source>Million loop steps per second in JavaScript</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage">
        <location filename="../qml/pages/MainPage.qml" line="218"/>
        <source>Storage performance</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-storage">
        <location filename="../qml/pages/MainPage.qml" line="220"/>
        <source>Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-storage">
        <location filename="../qml/pages/MainPage.qml" line="222"/>
        <source>Megabytes read and written per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-load-error">
        <location filename="../qml/pages/MainPage.qml" line="699"/>
        <source>could not be loaded</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-settings">
        <location filename="../qml/pages/MainPage.qml" line="989"/>
        <location filename="../qml/pages/ResultsPane.qml" line="35"/>
        <location filename="../qml/pages/SettingsPage.qml" line="112"/>
        <source>Settings</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-select-all">
        <location filename="../qml/pages/MainPage.qml" line="994"/>
        <source>Select all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-deselect-all">
        <location filename="../qml/pages/MainPage.qml" line="999"/>
        <source>Deselect all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-calibrate">
        <location filename="../qml/pages/MainPage.qml" line="1104"/>
        <source>The first run also finds each graphics stage&apos;s load, a few seconds per stage.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-calibrating">
        <location filename="../qml/pages/MainPage.qml" line="1226"/>
        <source>calibrating</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-hour">
        <location filename="../qml/pages/MainPage.qml" line="1294"/>
        <location filename="../qml/pages/ResultsView.qml" line="111"/>
        <location filename="../qml/pages/SettingsPage.qml" line="56"/>
        <source>Run one hour</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-loop">
        <location filename="../qml/pages/MainPage.qml" line="1296"/>
        <location filename="../qml/pages/ResultsView.qml" line="113"/>
        <location filename="../qml/pages/SettingsPage.qml" line="58"/>
        <source>Run in loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-once">
        <location filename="../qml/pages/MainPage.qml" line="1300"/>
        <source>For comparable results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-hour">
        <location filename="../qml/pages/MainPage.qml" line="1302"/>
        <source>A defined battery and temperature test, ends at 1:00:00. The display runs at 50 % brightness with automatic brightness off, and is set back afterwards.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-loop">
        <location filename="../qml/pages/MainPage.qml" line="1304"/>
        <source>Until you tap: overheating and throttling diagnosis</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-once">
        <location filename="../qml/pages/MainPage.qml" line="1292"/>
        <location filename="../qml/pages/ResultsView.qml" line="115"/>
        <location filename="../qml/pages/SettingsPage.qml" line="54"/>
        <source>Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-start">
        <location filename="../qml/pages/MainPage.qml" line="1116"/>
        <source>Start</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-next">
        <location filename="../qml/pages/MainPage.qml" line="1192"/>
        <source>Next: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tap-to-stop">
        <location filename="../qml/pages/MainPage.qml" line="1244"/>
        <source>Tap to stop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-loop-short">
        <location filename="../qml/pages/ResultsView.qml" line="134"/>
        <source>loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare">
        <location filename="../qml/pages/ComparePage.qml" line="64"/>
        <source>Compare</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-a">
        <location filename="../qml/pages/ComparePage.qml" line="75"/>
        <source>A: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-b">
        <location filename="../qml/pages/ComparePage.qml" line="78"/>
        <source>B: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-scenes">
        <location filename="../qml/pages/ComparePage.qml" line="81"/>
        <source>Different scenes: these scores do not compare.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-stage">
        <location filename="../qml/pages/ComparePage.qml" line="98"/>
        <location filename="../qml/pages/ResultsView.qml" line="289"/>
        <source>Stage</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-avg">
        <location filename="../qml/pages/ResultsView.qml" line="651"/>
        <source>avg</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-kernel">
        <location filename="../qml/pages/ResultsView.qml" line="91"/>
        <source>Kernel</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-device">
        <location filename="../qml/pages/ResultsView.qml" line="93"/>
        <source>Device</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-time">
        <location filename="../qml/pages/ResultsView.qml" line="95"/>
        <source>Date and runtime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-os">
        <location filename="../qml/pages/ResultsView.qml" line="97"/>
        <source>SailfishOS version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gpu">
        <location filename="../qml/pages/ResultsView.qml" line="99"/>
        <source>GPU</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-resolution">
        <location filename="../qml/pages/ResultsView.qml" line="101"/>
        <source>Screen resolution</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-render">
        <location filename="../qml/pages/ResultsView.qml" line="103"/>
        <source>Render size</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gl">
        <location filename="../qml/pages/ResultsView.qml" line="105"/>
        <source>OpenGL version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode">
        <location filename="../qml/pages/ResultsView.qml" line="107"/>
        <source>Run mode</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-render-size">
        <location filename="../qml/pages/ResultsView.qml" line="129"/>
        <source>drawn at %1 × %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-last-run">
        <location filename="../qml/pages/ResultsView.qml" line="144"/>
        <source>of the last run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode-once">
        <location filename="../qml/pages/ResultsView.qml" line="146"/>
        <source>only when not Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-score">
        <location filename="../qml/pages/ResultsView.qml" line="318"/>
        <source>score</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-direct">
        <location filename="../qml/pages/ResultsView.qml" line="345"/>
        <source>* without O_DIRECT: the read may come from the cache</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-calibrated-now">
        <location filename="../qml/pages/ResultsView.qml" line="362"/>
        <source>Load found in this run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-recalibrate-next">
        <location filename="../qml/pages/ResultsView.qml" line="364"/>
        <source>Ran too light, found again next run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-recalibrate-heavy">
        <location filename="../qml/pages/ResultsView.qml" line="366"/>
        <source>Ran too heavy, found again next run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-capped">
        <location filename="../qml/pages/ResultsView.qml" line="368"/>
        <source>Near the display&apos;s refresh rate, the score may be capped: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-topped">
        <location filename="../qml/pages/ResultsView.qml" line="370"/>
        <source>At the heaviest load and still fast, the score is a lower bound: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-partial">
        <location filename="../qml/pages/ResultsView.qml" line="372"/>
        <source>Stopped early, fewer seconds measured: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-single">
        <location filename="../qml/pages/ResultsView.qml" line="374"/>
        <source>Measured at one load only, the frame&apos;s own cost is in the score: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-noisy">
        <location filename="../qml/pages/ResultsView.qml" line="376"/>
        <source>Mostly frame overhead, the score is less certain: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-overhead">
        <location filename="../qml/pages/ResultsView.qml" line="378"/>
        <source>Every frame costs %1 ms besides the work (compositing, scaling to the screen); the scores leave it out</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-scene">
        <location filename="../qml/pages/ResultsView.qml" line="381"/>
        <source>Scene %1: these scores do not compare with %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unsupported">
        <location filename="../qml/pages/ResultsView.qml" line="400"/>
        <source>– cannot run on this GPU or driver</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-temperature">
        <location filename="../qml/pages/ResultsView.qml" line="418"/>
        <source>Temperature</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-battery">
        <location filename="../qml/pages/ResultsView.qml" line="484"/>
        <source>Battery</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-clocks">
        <location filename="../qml/pages/ResultsView.qml" line="569"/>
        <source>Clocks</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-brightness">
        <location filename="../qml/pages/ResultsView.qml" line="657"/>
        <source>brightness</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-set-by-run">
        <location filename="../qml/pages/ResultsView.qml" line="659"/>
        <source>set by the run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-charging">
        <location filename="../qml/pages/ResultsView.qml" line="661"/>
        <source>charging</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-not-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="672"/>
        <source>not throttled</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="674"/>
        <source>throttled %1 % of the run, first at %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-back-to-stages">
        <location filename="../qml/pages/ResultsPane.qml" line="41"/>
        <source>Back to stages</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-image">
        <location filename="../qml/pages/ResultsPane.qml" line="51"/>
        <source>Share image</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-assembling">
        <location filename="../qml/pages/ResultsPane.qml" line="99"/>
        <source>Assembling screenshot…</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-saved-in">
        <location filename="../qml/pages/ResultsPane.qml" line="144"/>
        <source>Saved to %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-not-saved">
        <location filename="../qml/pages/ResultsPane.qml" line="146"/>
        <source>Could not save the picture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-json">
        <location filename="../qml/pages/ResultsPane.qml" line="46"/>
        <source>Share JSON</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-share-results">
        <location filename="../qml/pages/ResultsPane.qml" line="123"/>
        <source>Share results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-peak">
        <location filename="../qml/pages/ResultsView.qml" line="683"/>
        <source>peak</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-writing">
        <location filename="../qml/stages/Storage.qml" line="74"/>
        <location filename="../qml/stages/Storage.qml" line="82"/>
        <source>Writing</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-reading">
        <location filename="../qml/stages/Storage.qml" line="74"/>
        <location filename="../qml/stages/Storage.qml" line="84"/>
        <source>Reading</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage-rw">
        <location filename="../qml/stages/Storage.qml" line="92"/>
        <location filename="../qml/stages/Storage.qml" line="95"/>
        <location filename="../qml/stages/Storage.qml" line="96"/>
        <source>stopped before it finished</source>
        <oldsource>Storage R/W</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-storage-stopped">
        <location filename="../qml/stages/Storage.qml" line="95"/>
        <source></source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stages-count">
        <location filename="../qml/pages/SettingsPage.qml" line="79"/>
        <source>Stages: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tab-results">
        <location filename="../qml/pages/SettingsPage.qml" line="116"/>
        <source>Results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-section-hints">
        <location filename="../qml/pages/SettingsPage.qml" line="142"/>
        <source>Display hints and descriptions</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-hints">
        <location filename="../qml/pages/SettingsPage.qml" line="147"/>
        <source>Show hints on the start page</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-hints-about">
        <location filename="../qml/pages/SettingsPage.qml" line="149"/>
        <source>A stage&apos;s description on a tap of its name, and what the chosen run mode is for.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-score-about">
        <location filename="../qml/pages/SettingsPage.qml" line="157"/>
        <source>Score descriptions in the results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-score-about-about">
        <location filename="../qml/pages/SettingsPage.qml" line="159"/>
        <source>A tap on a stage in the results opens a line on what its score counts.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-details">
        <location filename="../qml/pages/SettingsPage.qml" line="167"/>
        <source>Show system details in the results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-details-all">
        <location filename="../qml/pages/SettingsPage.qml" line="176"/>
        <source>All</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-details-none">
        <location filename="../qml/pages/SettingsPage.qml" line="178"/>
        <source>None</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-pick">
        <location filename="../qml/pages/SettingsPage.qml" line="234"/>
        <source>Tap a run to compare with %1, or tap it again to cancel</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-runs">
        <location filename="../qml/pages/SettingsPage.qml" line="242"/>
        <source>No saved runs yet</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-runs-hint">
        <location filename="../qml/pages/SettingsPage.qml" line="244"/>
        <source>Every run is kept here, the newest first.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-with">
        <location filename="../qml/pages/SettingsPage.qml" line="261"/>
        <source>Compare with…</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-delete">
        <location filename="../qml/pages/SettingsPage.qml" line="269"/>
        <source>Delete</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-this-run">
        <location filename="../qml/pages/SettingsPage.qml" line="288"/>
        <source>this run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-boats">
        <location filename="../qml/stages/BenchyHigh.qml" line="19"/>
        <location filename="../qml/stages/BenchyLow.qml" line="19"/>
        <source>boats/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-reads">
        <location filename="../qml/stages/BufferStage.qml" line="26"/>
        <source>M reads/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-squares">
        <location filename="../qml/stages/Cascade.qml" line="19"/>
        <source>squares/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-mpx">
        <location filename="../qml/stages/Glow.qml" line="21"/>
        <location filename="../qml/stages/ShaderHigh.qml" line="19"/>
        <location filename="../qml/stages/ShaderLow.qml" line="19"/>
        <source>Mpx/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-icons">
        <location filename="../qml/stages/Icons.qml" line="18"/>
        <source>icons/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-layers">
        <location filename="../qml/stages/Overdraw.qml" line="18"/>
        <source>layers/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-texts">
        <location filename="../qml/stages/Reraster.qml" line="23"/>
        <location filename="../qml/stages/Scale.qml" line="21"/>
        <source>texts/s</source>
        <translation type="unfinished"></translation>
    </message>
</context>
</TS>
