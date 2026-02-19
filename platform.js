let text = `<div id=\"topbar\"><link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
<a href="main.html"><img align=left style="margin-right:5px;padding:0px;height:50px;width:200px;"
src="https://github.com/WizzardSK/es-theme-carbon/raw/refs/heads/master/art/logos/${location.pathname.split('/').pop().replace(/\.html?$/, '')}.svg"></a>
<input type=\"text\" id=\"filterInput\" placeholder=\"Filter...\">
<input type=\"radio\" name=\"thumbtype\" id=\"Snaps\" value=\"Snaps\" checked onclick=\"processImages('snaps')\"><label for=\"Snaps\">Snaps</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Titles\" value=\"Titles\" onclick=\"processImages('titles')\"><label for=\"Titles\">Titles</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Boxarts\" value=\"Boxarts\" onclick=\"processImages('boxarts')\"><label for=\"Boxarts\">Boxarts</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Logos\" value=\"Logos\" onclick=\"processImages('logos')\"><label for=\"Logos\">Logos</label>
<input type=\"radio\" name=\"size\" id=\"80px\" value=\"80px\" onclick=\"changeSize(80)\"><label for=\"80px\">80px</label>
<input type=\"radio\" name=\"size\" id=\"120px\" value=\"120px\" onclick=\"changeSize(120)\"><label for=\"120px\">120px</label>
<input type=\"radio\" name=\"size\" id=\"160px\" value=\"160px\" onclick=\"changeSize(160)\" checked><label for=\"160px\">160px</label>
<input type=\"radio\" name=\"size\" id=\"240px\" value=\"240px\" onclick=\"changeSize(240)\"><label for=\"240px\">240px</label>
<input type=\"radio\" name=\"size\" id=\"320px\" value=\"320px\" onclick=\"changeSize(320)\"><label for=\"320px\">320px</label>
<br />
<span id=\"pocet\"></span>
<input type=\"checkbox\" id=\"showHideProto\" checked><label for=\"showHideProto\">Proto</label>
<input type=\"checkbox\" id=\"showHideProgram\" checked><label for=\"showHideProgram\">Program</label>
<input type=\"checkbox\" id=\"showHideAlfa\"><label for=\"showHideAlfa\">Alpha</label>
<input type=\"checkbox\" id=\"showHideBeta\"><label for=\"showHideBeta\">Beta</label>
<input type=\"checkbox\" id=\"showHidePrerelease\"><label for=\"showHidePrerelease\">Pre</label>
<input type=\"checkbox\" id=\"showHideDemo\"><label for=\"showHideDemo\">Demo</label>
<input type=\"checkbox\" id=\"showHideAftermarket\"><label for=\"showHideAftermarket\">After</label>
<input type=\"checkbox\" id=\"showHideUnl\"><label for=\"showHideUnl\">Unl</label>
<input type=\"checkbox\" id=\"showHideAlt\"><label for=\"showHideAlt\">Alt</label>
<input type=\"checkbox\" id=\"showHidePirate\"><label for=\"showHidePirate\">Pirate</label>
<input type=\"checkbox\" id=\"showHideBrackets\"><label for=\"showHideBrackets\">[a][b]</label>
<input type=\"checkbox\" id=\"showHideDisk\"><label for=\"showHideDisk\">[disk2]</label>
<div id="navlinks"></div></div>`;

document.write(text);

var _bgPlatform;
function bgImage(platform) {
    if (_bgPlatform !== platform) {
        _bgPlatform = platform;
        document.write(`<style> figure { background-image: url('https://raw.githubusercontent.com/WizzardSK/es-theme-carbon/master/art/consoles/${platform}.png'); } </style>`);
    }
}

function generateTicLinks(romPath, imagePath) {
    romPath = romPath.replace("roms/TIC-80", "https://tic80.com/play?cart=");
    var html = [];
    fileNames.forEach(fileName => {
        var [id, hash, nazov] = fileName.split('\t');
        html.push(`<a href="${romPath}${id}" target="main">
        <figure><img loading="lazy" src="https://tic80.com/cart/${hash}/cover.gif" alt="${nazov}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}

function generateWasmLinks(romPath, imagePath) {
    romPath = romPath.replace("roms/WASM-4", "https://wasm4.org/play");
    var html = [];
    fileNames.forEach(fileName => {
        var [subor, nazov] = fileName.split('\t');
        html.push(`<a href="${romPath}/${encodeURIComponent(subor)}" target="main">
        <figure><img loading="lazy" src="https://wasm4.org/carts/${subor}.png" alt="${nazov}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}

function generateLrNXLinks(romPath, imagePath) {
    romPath = romPath.replace("roms/LowresNX", "https://lowresnx.inutilis.com/topic.php?id=");
    var html = [];
    fileNames.forEach(fileName => {
        var [subor, obrazok, nazov, id] = fileName.split('\t');
        html.push(`<a href="${romPath}${encodeURIComponent(id)}" target="main">
        <figure><img loading="lazy" src="https://lowresnx.inutilis.com/uploads/${obrazok}" alt="${nazov}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}

function generatePicoLinks(romPath, imagePath) {
    var html = [];
    fileNames.forEach(fileName => {
        var [id, nazov, kart] = fileName.split('\t');
        var screen = /^\d/.test(kart) ? "pico" + kart.replace(/\.p8\.png$/, '.png') : kart.replace(/^(.*)\.p8\.png$/, 'pico8_$1.png');
        var cart = kart.replace(/\.p8.png$/, "");
        html.push(`<a href="https://www.lexaloffle.com/bbs/?pid=${cart}#p" target="main">
        <figure><img loading="lazy" src="https://www.lexaloffle.com/bbs/thumbs/${screen}" alt="${nazov}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}

function generateVoxLinks(romPath, imagePath) {
    var html = [];
    fileNames.forEach(fileName => {
        var [id, nazov, kart] = fileName.split('\t');
        var screen = kart.replace(/^(.*)\.vx\.png$/, 'vox_$1.png').replace(/^cpost/, "vox");
        var cart = kart.replace(/^cpost/, "").replace(/\.png$/, "");
        html.push(`<a href="https://www.lexaloffle.com/bbs/?pid=${cart}#p" target="main">
        <figure><img loading="lazy" src="https://www.lexaloffle.com/bbs/thumbs/${screen}" alt="${nazov}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}

function generateFileLinks(romPath, imagePath) {
    if (location.protocol !== "file:") {
        if (romPath.startsWith("myrient/")) { romPath = romPath.replace("myrient", "https://myrient.erista.me/files"); }
        if (romPath.includes("2600")) { romPath = "https://javatari.org/?rom=" + romPath; romPath = romPath.replace("&", "%26"); romPath = romPath.replace(" ", "%20"); }
    } else { romPath = "../" + romPath }
    var encodedPath = encodeURI(romPath);
    var html = [];
    fileNames.forEach(fileName => {
        var subor = fileName.includes("\t") ? fileName.split("\t")[0] : fileName;
        var nameWithoutExt = subor.includes(".") ? subor.slice(0, subor.lastIndexOf(".")) : subor;
        var nameWithoutBrackets = nameWithoutExt.replace(/^([^)]*\([^)]*\)).*$/, "$1");
        var nazov = fileName.includes("\t") ? fileName.split("\t")[1] : fileName.replace(/\.[^.]+$/, "");
        html.push(`<a href="${encodedPath}/${encodeURIComponent(subor)}" target="main" rel="noreferrer">
        <figure><img loading="lazy" src="https://raw.githubusercontent.com/WizzardSK/${imagePath}/master/Named_Snaps/${encodeURIComponent(nameWithoutBrackets)}.png" alt="${nameWithoutExt}"><figcaption>${nazov}</figcaption></figure></a>`);
    });
    document.write('<div class="figureList">' + html.join('') + '</div>');
}
