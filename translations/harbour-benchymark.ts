<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1">
<context>
    <name></name>
    <message id="id-stage-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="63"/>
        <source>Benchy large</source>
        <oldsource>Benchy light</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="65"/>
        <source>Two large 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. A large boat has twice the lines&apos; length of a small one to draw, so fewer of them fit in a second. Scores boats per second.</source>
        <oldsource>Two 3DBenchy wireframes turning, each drawn many times on its spot: the lines are rotated and projected on the CPU, then stroked by the GPU. Scores boats per second.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-light">
        <location filename="../qml/pages/MainPage.qml" line="67"/>
        <source>Boats drawn per second, two large ones on screen</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="69"/>
        <source>Benchy small</source>
        <oldsource>Benchy heavy</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="71"/>
        <source>Six small boats, each drawn many times: the same work per boat on the CPU, half the lines&apos; length for the GPU. Scores boats per second.</source>
        <oldsource>Six boats, each drawn many times: much more geometry than the picture shows. Scores boats per second.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-benchy-heavy">
        <location filename="../qml/pages/MainPage.qml" line="73"/>
        <source>Boats drawn per second, six small ones on screen</source>
        <oldsource>Boats drawn per second, six smaller ones on screen</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-glow">
        <location filename="../qml/pages/MainPage.qml" line="75"/>
        <source>Benchy glow</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-glow">
        <location filename="../qml/pages/MainPage.qml" line="77"/>
        <source>A Benchy with a pulsing golden halo, the glow stacked several times: a blur over the whole picture each, the cost of soft effects. Scores megapixels per second.</source>
        <oldsource>A Benchy with a pulsing golden halo: a blur over the whole screen every frame, the cost of soft effects.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-glow">
        <location filename="../qml/pages/MainPage.qml" line="79"/>
        <source>Megapixels blurred per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="81"/>
        <source>Shader light</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="83"/>
        <source>A drifting noise field computed for every pixel, several times over: GPU arithmetic. Scores megapixels per second.</source>
        <oldsource>A drifting noise field computed for every pixel: GPU arithmetic that grows with the screen size.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-light">
        <location filename="../qml/pages/MainPage.qml" line="85"/>
        <source>Megapixels of noise field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="87"/>
        <source>Shader heavy</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="89"/>
        <source>The same idea warped twice over, about thirty noise lookups per pixel and field: the heaviest GPU arithmetic here. Scores megapixels per second.</source>
        <oldsource>The same idea warped twice over, about thirty noise lookups per pixel: the heaviest GPU load here.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-shader-heavy">
        <location filename="../qml/pages/MainPage.qml" line="91"/>
        <source>Megapixels of warped field per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="94"/>
        <source>Table from UBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="96"/>
        <source>Every pixel walks a 16 KB table, each index taken from the entry before, here from a uniform buffer (UBO). Scores million table reads per second. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ubo">
        <location filename="../qml/pages/MainPage.qml" line="98"/>
        <source>Million table reads per second from a uniform buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="100"/>
        <source>Table from SSBO</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="102"/>
        <source>The same table walk from a shader storage buffer (SSBO). Needs OpenGL ES 3.1 and a driver that allows them in fragment shaders.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-ssbo">
        <location filename="../qml/pages/MainPage.qml" line="104"/>
        <source>Million table reads per second from a storage buffer</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="106"/>
        <source>Table from texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="108"/>
        <source>The same table walk from a float texture, the classic way and the baseline for the two buffers. Needs OpenGL ES 3.0.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-buffer-texture">
        <location filename="../qml/pages/MainPage.qml" line="110"/>
        <source>Million table reads per second from a texture</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="112"/>
        <source>Overdraw</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="114"/>
        <source>Large translucent squares stacked and turning: every pixel is blended many times, raw fill rate. Scores layers per second.</source>
        <oldsource>72 large translucent squares stacked and turning: every pixel is blended many times, raw fill rate.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-overdraw">
        <location filename="../qml/pages/MainPage.qml" line="116"/>
        <source>Translucent layers blended per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cascade">
        <location filename="../qml/pages/MainPage.qml" line="118"/>
        <source>Cascade</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cascade">
        <location filename="../qml/pages/MainPage.qml" line="120"/>
        <source>Thousands of rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents. Scores squares per second.</source>
        <oldsource>A thousand rounded squares in two breathing, counter-rotating rings: many moving items under transformed parents.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cascade">
        <location filename="../qml/pages/MainPage.qml" line="122"/>
        <source>Squares moved per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-icons">
        <location filename="../qml/pages/MainPage.qml" line="124"/>
        <source>Icon storm</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-icons">
        <location filename="../qml/pages/MainPage.qml" line="126"/>
        <source>Rockets and flashes on spiral arms, stacked: many small images moving every frame. Scores icons per second.</source>
        <oldsource>Rockets and flashes on spiral arms, each icon drawn three times: many small images moving every frame.</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-icons">
        <location filename="../qml/pages/MainPage.qml" line="128"/>
        <source>Icons drawn per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu">
        <location filename="../qml/pages/MainPage.qml" line="130"/>
        <location filename="../qml/stages/CpuPrime.qml" line="22"/>
        <source>CPU prime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu">
        <location filename="../qml/pages/MainPage.qml" line="132"/>
        <source>All cores count primes as sysbench does; every finished count lights a cell of an Ulam spiral if its number is prime.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu">
        <location filename="../qml/pages/MainPage.qml" line="134"/>
        <source>Prime counts per second on all cores</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="136"/>
        <location filename="../qml/stages/CpuPrimeSingle.qml" line="11"/>
        <source>CPU single core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="138"/>
        <source>The same prime counting on one core only: next to the all core figure it shows what a single core does.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-cpu-single">
        <location filename="../qml/pages/MainPage.qml" line="140"/>
        <source>Prime counts per second on one core</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-memory">
        <location filename="../qml/pages/MainPage.qml" line="142"/>
        <location filename="../qml/stages/Memory.qml" line="120"/>
        <source>Memory throughput</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-memory">
        <location filename="../qml/pages/MainPage.qml" line="144"/>
        <source>Copies memory between two 32 MB buffers as fast as it can: how quickly the phone moves data in RAM.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-memory">
        <location filename="../qml/pages/MainPage.qml" line="146"/>
        <source>Megabytes copied per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-million">
        <location filename="../qml/pages/MainPage.qml" line="148"/>
        <location filename="../qml/stages/OneMillion.qml" line="91"/>
        <source>One million</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-million">
        <location filename="../qml/pages/MainPage.qml" line="150"/>
        <source>JavaScript counts to one million, over and over: how fast the app&apos;s script engine runs a plain loop.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-million">
        <location filename="../qml/pages/MainPage.qml" line="152"/>
        <source>Million loop steps per second in JavaScript</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-storage">
        <location filename="../qml/pages/MainPage.qml" line="155"/>
        <source>Storage performance</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-about-storage">
        <location filename="../qml/pages/MainPage.qml" line="157"/>
        <source>Writes 256 MB in small blocks past the cache and reads it back. Off by default: it wears the flash a little every run.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-score-storage">
        <location filename="../qml/pages/MainPage.qml" line="159"/>
        <source>Megabytes read and written per second</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-stage-load-error">
        <location filename="../qml/pages/MainPage.qml" line="452"/>
        <location filename="../qml/pages/MainPage.qml" line="558"/>
        <location filename="../qml/pages/MainPage.qml" line="646"/>
        <source>could not be loaded</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-settings">
        <location filename="../qml/pages/MainPage.qml" line="832"/>
        <location filename="../qml/pages/ResultsPane.qml" line="35"/>
        <location filename="../qml/pages/SettingsPage.qml" line="117"/>
        <source>Settings</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-select-all">
        <location filename="../qml/pages/MainPage.qml" line="837"/>
        <source>Select all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-deselect-all">
        <location filename="../qml/pages/MainPage.qml" line="842"/>
        <source>Deselect all</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-hour">
        <location filename="../qml/pages/MainPage.qml" line="1143"/>
        <location filename="../qml/pages/ResultsView.qml" line="95"/>
        <location filename="../qml/pages/SettingsPage.qml" line="61"/>
        <source>Run one hour</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-loop">
        <location filename="../qml/pages/MainPage.qml" line="1145"/>
        <location filename="../qml/pages/ResultsView.qml" line="97"/>
        <location filename="../qml/pages/SettingsPage.qml" line="63"/>
        <source>Run in loop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-once">
        <location filename="../qml/pages/MainPage.qml" line="1149"/>
        <source>For comparable results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-hour">
        <location filename="../qml/pages/MainPage.qml" line="1151"/>
        <source>A defined battery and temperature test, ends at 1:00:00. The display runs at 50 % brightness with automatic brightness off, and is set back afterwards.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-hint-loop">
        <location filename="../qml/pages/MainPage.qml" line="1153"/>
        <source>Until you tap: overheating and throttling diagnosis</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-run-once">
        <location filename="../qml/pages/MainPage.qml" line="1141"/>
        <location filename="../qml/pages/ResultsView.qml" line="99"/>
        <location filename="../qml/pages/SettingsPage.qml" line="59"/>
        <source>Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-start">
        <location filename="../qml/pages/MainPage.qml" line="954"/>
        <source>Start</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-next">
        <location filename="../qml/pages/MainPage.qml" line="1046"/>
        <source>Next: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tap-to-stop">
        <location filename="../qml/pages/MainPage.qml" line="1093"/>
        <source>Tap to stop</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-loop-short">
        <location filename="../qml/pages/ResultsView.qml" line="118"/>
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
        <location filename="../qml/pages/ResultsView.qml" line="273"/>
        <source>Stage</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-avg">
        <location filename="../qml/pages/ResultsView.qml" line="621"/>
        <source>avg</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-kernel">
        <location filename="../qml/pages/ResultsView.qml" line="75"/>
        <source>Kernel</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-device">
        <location filename="../qml/pages/ResultsView.qml" line="77"/>
        <source>Device</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-time">
        <location filename="../qml/pages/ResultsView.qml" line="79"/>
        <source>Date and runtime</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-os">
        <location filename="../qml/pages/ResultsView.qml" line="81"/>
        <source>SailfishOS version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gpu">
        <location filename="../qml/pages/ResultsView.qml" line="83"/>
        <source>GPU</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-resolution">
        <location filename="../qml/pages/ResultsView.qml" line="85"/>
        <source>Screen resolution</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-render">
        <location filename="../qml/pages/ResultsView.qml" line="87"/>
        <source>Render size</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-gl">
        <location filename="../qml/pages/ResultsView.qml" line="89"/>
        <source>OpenGL version</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode">
        <location filename="../qml/pages/ResultsView.qml" line="91"/>
        <source>Run mode</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-render-size">
        <location filename="../qml/pages/ResultsView.qml" line="113"/>
        <source>drawn at %1 × %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-last-run">
        <location filename="../qml/pages/ResultsView.qml" line="128"/>
        <source>of the last run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-detail-mode-once">
        <location filename="../qml/pages/ResultsView.qml" line="130"/>
        <source>only when not Run once</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-col-score">
        <location filename="../qml/pages/ResultsView.qml" line="302"/>
        <source>score</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-direct">
        <location filename="../qml/pages/ResultsView.qml" line="329"/>
        <source>* without O_DIRECT: the read may come from the cache</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-partial">
        <location filename="../qml/pages/ResultsView.qml" line="346"/>
        <source>Stopped early, fewer seconds measured: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-spread">
        <location filename="../qml/pages/ResultsView.qml" line="348"/>
        <source>Uncertain by more than ±10 % (the two halves of its measurement differ): %1</source>
        <oldsource>Uncertain by more than ±10 % (its two measurements differ): %1</oldsource>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-flag-scene">
        <location filename="../qml/pages/ResultsView.qml" line="351"/>
        <source>Scene %1: these scores do not compare with %2</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unsupported">
        <location filename="../qml/pages/ResultsView.qml" line="370"/>
        <source>– cannot run on this GPU or driver</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-temperature">
        <location filename="../qml/pages/ResultsView.qml" line="388"/>
        <source>Temperature</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-battery">
        <location filename="../qml/pages/ResultsView.qml" line="454"/>
        <source>Battery</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-clocks">
        <location filename="../qml/pages/ResultsView.qml" line="539"/>
        <source>Clocks</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-brightness">
        <location filename="../qml/pages/ResultsView.qml" line="627"/>
        <source>brightness</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-set-by-run">
        <location filename="../qml/pages/ResultsView.qml" line="629"/>
        <source>set by the run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-charging">
        <location filename="../qml/pages/ResultsView.qml" line="631"/>
        <source>charging</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-not-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="642"/>
        <source>not throttled</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-throttled">
        <location filename="../qml/pages/ResultsView.qml" line="644"/>
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
        <location filename="../qml/pages/ResultsView.qml" line="653"/>
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
        <location filename="../qml/pages/SettingsPage.qml" line="84"/>
        <source>Stages: %1</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-tab-results">
        <location filename="../qml/pages/SettingsPage.qml" line="121"/>
        <source>Results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-section-running">
        <location filename="../qml/pages/SettingsPage.qml" line="147"/>
        <source>Running</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-motion">
        <location filename="../qml/pages/SettingsPage.qml" line="151"/>
        <source>Show stages moving</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-motion-about">
        <location filename="../qml/pages/SettingsPage.qml" line="153"/>
        <source>Each graphics stage plays two seconds on screen before it is measured off screen, where only its first frames show. Off: measuring only, two seconds shorter per stage. The scores are the same either way.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-section-hints">
        <location filename="../qml/pages/SettingsPage.qml" line="161"/>
        <source>Display hints and descriptions</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-hints">
        <location filename="../qml/pages/SettingsPage.qml" line="166"/>
        <source>Show hints on the start page</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-hints-about">
        <location filename="../qml/pages/SettingsPage.qml" line="168"/>
        <source>A stage&apos;s description on a tap of its name, and what the chosen run mode is for.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-score-about">
        <location filename="../qml/pages/SettingsPage.qml" line="176"/>
        <source>Score descriptions in the results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-score-about-about">
        <location filename="../qml/pages/SettingsPage.qml" line="178"/>
        <source>A tap on a stage in the results opens a line on what its score counts.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-setting-details">
        <location filename="../qml/pages/SettingsPage.qml" line="186"/>
        <source>Show system details in the results</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-details-all">
        <location filename="../qml/pages/SettingsPage.qml" line="195"/>
        <source>All</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-details-none">
        <location filename="../qml/pages/SettingsPage.qml" line="197"/>
        <source>None</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-pick">
        <location filename="../qml/pages/SettingsPage.qml" line="253"/>
        <source>Tap a run to compare with %1, or tap it again to cancel</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-runs">
        <location filename="../qml/pages/SettingsPage.qml" line="261"/>
        <source>No saved runs yet</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-no-runs-hint">
        <location filename="../qml/pages/SettingsPage.qml" line="263"/>
        <source>Every run is kept here, the newest first.</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-compare-with">
        <location filename="../qml/pages/SettingsPage.qml" line="280"/>
        <source>Compare with…</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-delete">
        <location filename="../qml/pages/SettingsPage.qml" line="288"/>
        <source>Delete</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-this-run">
        <location filename="../qml/pages/SettingsPage.qml" line="307"/>
        <source>this run</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-boats">
        <location filename="../qml/stages/BenchyHigh.qml" line="21"/>
        <location filename="../qml/stages/BenchyLow.qml" line="21"/>
        <source>boats/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-reads">
        <location filename="../qml/stages/BufferStage.qml" line="23"/>
        <source>M reads/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-squares">
        <location filename="../qml/stages/Cascade.qml" line="20"/>
        <source>squares/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-mpx">
        <location filename="../qml/stages/Glow.qml" line="22"/>
        <location filename="../qml/stages/ShaderHigh.qml" line="19"/>
        <location filename="../qml/stages/ShaderLow.qml" line="19"/>
        <source>Mpx/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-icons">
        <location filename="../qml/stages/Icons.qml" line="19"/>
        <source>icons/s</source>
        <translation type="unfinished"></translation>
    </message>
    <message id="id-unit-layers">
        <location filename="../qml/stages/Overdraw.qml" line="19"/>
        <source>layers/s</source>
        <translation type="unfinished"></translation>
    </message>
</context>
</TS>
