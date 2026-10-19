<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1">
<context>
    <name></name>
    <message id="id-stage-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="131"/>
        <source>Benchy large</source>
        <oldsource>Benchy light</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="133"/>
        <source>Two large 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. A large boat has twice the lines&apos; length of a small one to draw, so fewer of them fit in a second. Scores boats per second.</source>
        <oldsource>Two 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. Scores boats per second.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="135"/>
        <source>Boats drawn per second, two large ones on screen</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="137"/>
        <source>Benchy small</source>
        <oldsource>Benchy heavy</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="139"/>
        <source>Six small boats, each drawn many times: the same work per boat on the CPU, half the lines&apos; length for the GPU. Scores boats per second.</source>
        <oldsource>Six boats, each drawn many times: much more geometry than the picture shows. Scores boats per second.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="141"/>
        <source>Boats drawn per second, six small ones on screen</source>
        <oldsource>Boats drawn per second, six smaller ones on screen</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-glow">
        <location filename="../qml/pages/MainPage.qml" line="143"/>
        <source>Benchy glow</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-glow">
        <location filename="../qml/pages/MainPage.qml" line="145"/>
        <source>A Benchy with a pulsing golden halo, the glow stacked several times: a blur over the whole picture each, the cost of soft effects. Scores megapixels per second.</source>
        <oldsource>A Benchy with a pulsing golden halo: a blur over the whole screen every frame, the cost of soft effects.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-glow">
        <location filename="../qml/pages/MainPage.qml" line="147"/>
        <source>Megapixels blurred per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="149"/>
        <source>Shader light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="151"/>
        <source>A drifting noise field computed for every pixel, several times over: GPU arithmetic. Scores megapixels per second.</source>
        <oldsource>A drifting noise field computed for every pixel: GPU arithmetic that grows with the screen size.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="153"/>
        <source>Megapixels of noise field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="155"/>
        <source>Shader heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="157"/>
        <source>The same idea warped twice over, about thirty noise lookups per pixel and field: the heaviest GPU arithmetic here. Scores megapixels per second.</source>
        <oldsource>The same idea warped twice over, about thirty noise lookups per pixel: the heaviest GPU load here.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="159"/>
        <source>Megapixels of warped field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="162"/>
        <source>Table from UBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="164"/>
        <source>Every pixel walks a 16 KB table, each index taken from the entry before, here from a uniform buffer (UBO). Scores million table reads per second. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="166"/>
        <source>Million table reads per second from a uniform buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="168"/>
        <source>Table from SSBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="170"/>
        <source>The same table walk from a shader storage buffer (SSBO). Needs OpenGL ES 3.1 and a driver that allows them in fragment shaders.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="172"/>
        <source>Million table reads per second from a storage buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="174"/>
        <source>Table from texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="176"/>
        <source>The same table walk from a float texture, the classic way and the baseline for the two buffers. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="178"/>
        <source>Million table reads per second from a texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="180"/>
        <source>Overdraw</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="182"/>
        <source>Large translucent squares stacked and turning: every pixel is blended many times, raw fill rate. Scores layers per second.</source>
        <oldsource>72 large translucent squares stacked and turning: every pixel is blended many times, raw fill rate.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="184"/>
        <source>Translucent layers blended per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cascade">
        <location filename="../qml/pages/MainPage.qml" line="186"/>
        <source>Cascade</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cascade">
        <location filename="../qml/pages/MainPage.qml" line="188"/>
        <source>Thousands of rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents. Scores squares per second.</source>
        <oldsource>A thousand rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cascade">
        <location filename="../qml/pages/MainPage.qml" line="190"/>
        <source>Squares moved per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-icons">
        <location filename="../qml/pages/MainPage.qml" line="192"/>
        <source>Icon storm</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-icons">
        <location filename="../qml/pages/MainPage.qml" line="194"/>
        <source>Rockets and flashes on spiral arms, stacked: many small images moving every frame. Scores icons per second.</source>
        <oldsource>Rockets and flashes on spiral arms, each icon drawn three times: many small images moving every frame.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-icons">
        <location filename="../qml/pages/MainPage.qml" line="196"/>
        <source>Icons drawn per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu">
        <location filename="../qml/pages/MainPage.qml" line="198"/>
        <location filename="../qml/stages/CpuPrime.qml" line="22"/>
        <source>CPU prime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu">
        <location filename="../qml/pages/MainPage.qml" line="200"/>
        <source>All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu">
        <location filename="../qml/pages/MainPage.qml" line="202"/>
        <source>Prime counts per second on all cores</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="204"/>
        <location filename="../qml/stages/CpuPrimeSingle.qml" line="11"/>
        <source>CPU single core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="206"/>
        <source>The same prime counting on one core only: next to the all core figure it shows what a single core does.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="208"/>
        <source>Prime counts per second on one core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-memory">
        <location filename="../qml/pages/MainPage.qml" line="210"/>
        <location filename="../qml/stages/Memory.qml" line="120"/>
        <source>Memory throughput</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-memory">
        <location filename="../qml/pages/MainPage.qml" line="212"/>
        <source>Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-memory">
        <location filename="../qml/pages/MainPage.qml" line="214"/>
        <source>Megabytes copied per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-million">
        <location filename="../qml/pages/MainPage.qml" line="216"/>
        <location filename="../qml/stages/OneMillion.qml" line="91"/>
        <source>One million</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-million">
        <location filename="../qml/pages/MainPage.qml" line="218"/>
        <source>JavaScript counts to one million, over and over: how fast the app&apos;s script engine runs a plain loop.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-million">
        <location filename="../qml/pages/MainPage.qml" line="220"/>
        <source>Million loop steps per second in JavaScript</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage">
        <location filename="../qml/pages/MainPage.qml" line="223"/>
        <source>Storage performance</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-storage">
        <location filename="../qml/pages/MainPage.qml" line="225"/>
        <source>Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-storage">
        <location filename="../qml/pages/MainPage.qml" line="227"/>
        <source>Megabytes read and written per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-load-error">
        <location filename="../qml/pages/MainPage.qml" line="738"/>
        <source>could not be loaded</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-settings">
        <location filename="../qml/pages/MainPage.qml" line="1064"/>
        <location filename="../qml/pages/ResultsPane.qml" line="35"/>
        <location filename="../qml/pages/SettingsPage.qml" line="112"/>
        <source>Settings</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-select-all">
        <location filename="../qml/pages/MainPage.qml" line="1069"/>
        <source>Select all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-deselect-all">
        <location filename="../qml/pages/MainPage.qml" line="1074"/>
        <source>Deselect all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-calibrate">
        <location filename="../qml/pages/MainPage.qml" line="1179"/>
        <source>The first run also finds each graphics stage&apos;s load, a few seconds per stage.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-calibrating">
        <location filename="../qml/pages/MainPage.qml" line="1301"/>
        <source>calibrating</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-hour">
        <location filename="../qml/pages/MainPage.qml" line="1367"/>
        <location filename="../qml/pages/ResultsView.qml" line="114"/>
        <location filename="../qml/pages/SettingsPage.qml" line="56"/>
        <source>Run one hour</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-loop">
        <location filename="../qml/pages/MainPage.qml" line="1369"/>
        <location filename="../qml/pages/ResultsView.qml" line="116"/>
        <location filename="../qml/pages/SettingsPage.qml" line="58"/>
        <source>Run in loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-once">
        <location filename="../qml/pages/MainPage.qml" line="1373"/>
        <source>For comparable results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-hour">
        <location filename="../qml/pages/MainPage.qml" line="1375"/>
        <source>A defined battery and temperature test, ends at 1:00:00. The display runs at 50 % brightness with automatic brightness off, and is set back afterwards.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-loop">
        <location filename="../qml/pages/MainPage.qml" line="1377"/>
        <source>Until you tap: overheating and throttling diagnosis</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-once">
        <location filename="../qml/pages/MainPage.qml" line="1365"/>
        <location filename="../qml/pages/ResultsView.qml" line="118"/>
        <location filename="../qml/pages/SettingsPage.qml" line="54"/>
        <source>Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-start">
        <location filename="../qml/pages/MainPage.qml" line="1191"/>
        <source>Start</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-next">
        <location filename="../qml/pages/MainPage.qml" line="1267"/>
        <source>Next: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tap-to-stop">
        <location filename="../qml/pages/MainPage.qml" line="1317"/>
        <source>Tap to stop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-loop-short">
        <location filename="../qml/pages/ResultsView.qml" line="137"/>
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
        <location filename="../qml/pages/ResultsView.qml" line="292"/>
        <source>Stage</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-avg">
        <location filename="../qml/pages/ResultsView.qml" line="656"/>
        <source>avg</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-kernel">
        <location filename="../qml/pages/ResultsView.qml" line="94"/>
        <source>Kernel</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-device">
        <location filename="../qml/pages/ResultsView.qml" line="96"/>
        <source>Device</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-time">
        <location filename="../qml/pages/ResultsView.qml" line="98"/>
        <source>Date and runtime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-os">
        <location filename="../qml/pages/ResultsView.qml" line="100"/>
        <source>SailfishOS version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gpu">
        <location filename="../qml/pages/ResultsView.qml" line="102"/>
        <source>GPU</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-resolution">
        <location filename="../qml/pages/ResultsView.qml" line="104"/>
        <source>Screen resolution</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-render">
        <location filename="../qml/pages/ResultsView.qml" line="106"/>
        <source>Render size</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gl">
        <location filename="../qml/pages/ResultsView.qml" line="108"/>
        <source>OpenGL version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode">
        <location filename="../qml/pages/ResultsView.qml" line="110"/>
        <source>Run mode</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-render-size">
        <location filename="../qml/pages/ResultsView.qml" line="132"/>
        <source>drawn at %1 × %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-last-run">
        <location filename="../qml/pages/ResultsView.qml" line="147"/>
        <source>of the last run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode-once">
        <location filename="../qml/pages/ResultsView.qml" line="149"/>
        <source>only when not Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-score">
        <location filename="../qml/pages/ResultsView.qml" line="321"/>
        <source>score</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-direct">
        <location filename="../qml/pages/ResultsView.qml" line="348"/>
        <source>* without O_DIRECT: the read may come from the cache</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-calibrated-now">
        <location filename="../qml/pages/ResultsView.qml" line="365"/>
        <source>Load found in this run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-recalibrate-next">
        <location filename="../qml/pages/ResultsView.qml" line="367"/>
        <source>Ran too light, found again next run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-recalibrate-heavy">
        <location filename="../qml/pages/ResultsView.qml" line="369"/>
        <source>Ran too heavy, found again next run: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-capped">
        <location filename="../qml/pages/ResultsView.qml" line="371"/>
        <source>Near the display&apos;s refresh rate, the score may be capped: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-topped">
        <location filename="../qml/pages/ResultsView.qml" line="373"/>
        <source>At the heaviest load and still fast, the score is a lower bound: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-partial">
        <location filename="../qml/pages/ResultsView.qml" line="375"/>
        <source>Stopped early, fewer seconds measured: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-single">
        <location filename="../qml/pages/ResultsView.qml" line="377"/>
        <source>Measured at one load only, the frame&apos;s own cost is in the score: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-spread">
        <location filename="../qml/pages/ResultsView.qml" line="379"/>
        <source>Uncertain by more than ±10 % (its two measurements differ): %1</source>
        <oldsource>Its two measurements lay more than 10 % apart: %1</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-superlinear">
        <location filename="../qml/pages/ResultsView.qml" line="381"/>
        <source>Frame time grew faster than the load, scored at one load: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-overhead">
        <location filename="../qml/pages/ResultsView.qml" line="383"/>
        <source>Every frame costs %1 ms besides the work (compositing, scaling to the screen); the scores leave it out</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-scene">
        <location filename="../qml/pages/ResultsView.qml" line="386"/>
        <source>Scene %1: these scores do not compare with %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unsupported">
        <location filename="../qml/pages/ResultsView.qml" line="405"/>
        <source>– cannot run on this GPU or driver</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-temperature">
        <location filename="../qml/pages/ResultsView.qml" line="423"/>
        <source>Temperature</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-battery">
        <location filename="../qml/pages/ResultsView.qml" line="489"/>
        <source>Battery</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-clocks">
        <location filename="../qml/pages/ResultsView.qml" line="574"/>
        <source>Clocks</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-brightness">
        <location filename="../qml/pages/ResultsView.qml" line="662"/>
        <source>brightness</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-set-by-run">
        <location filename="../qml/pages/ResultsView.qml" line="664"/>
        <source>set by the run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-charging">
        <location filename="../qml/pages/ResultsView.qml" line="666"/>
        <source>charging</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-not-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="677"/>
        <source>not throttled</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="679"/>
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
        <location filename="../qml/pages/ResultsView.qml" line="688"/>
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
        <location filename="../qml/stages/Storage.qml" line="94"/>
        <location filename="../qml/stages/Storage.qml" line="95"/>
        <location filename="../qml/stages/Storage.qml" line="100"/>
        <source>Storage R/W</source>
        <oldsource>stopped before it finished</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-storage-stopped">
        <location filename="../qml/stages/Storage.qml" line="102"/>
        <source>stopped before it finished</source>
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
</context>
</TS>
