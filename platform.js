let text = `<div id=\"topbar\"><link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
<a href="main.html"><img align=left style="margin-right:5px;padding:0px;height:50px;width:200px;"
src="https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/logos/${location.pathname.split('/').pop().replace(/\.html?$/, '')}.svg"></a>
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

// On Android, launch games in the native RetroArch app (intent://). No-op elsewhere.
document.write('<script src="intent.js"></script>');

var _bgPlatform;
function bgImage(platform) {
    if (_bgPlatform !== platform) {
        _bgPlatform = platform;
        document.write(`<style> figure { background-image: url('https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${platform}.png'); } </style>`);
    }
}

// Game lists are not written into the page as HTML. A platform like C64 has
// over 260,000 games, and a million-plus DOM nodes take the browser a minute to
// build. Each generate*Links() call instead registers its list here with a
// caption per game (for the filter) and a function that builds one game's
// markup; script.js creates markup only for the rows on screen.
var gfLists = [];

// Thumbnail set for generateFileLinks: _Snaps, _Titles, _Boxarts or _Logos
// (switched by processImages() in script.js).
var gfThumbType = '_Snaps';

function addFigureList(names, parse, render) {
    var captions = new Array(names.length);
    for (var i = 0; i < names.length; i++) captions[i] = parse(names[i]).nazov.toLowerCase();
    document.write('<div class="figureList" data-list="' + gfLists.length + '"></div>');
    gfLists.push({ captions: captions, render: function (i) { return render(parse(names[i])); } });
}

function figureHtml(href, img, alt, caption, attrs) {
    return `<a href="${href}" target="main"${attrs || ''}><figure><img loading="lazy" src="${img}" alt="${alt}"><figcaption>${caption}</figcaption></figure></a>`;
}

// TIC-80 carts are played locally, in tic80_libretro, not on tic80.com: the
// site sends X-Frame-Options: SAMEORIGIN, so its player can never load in the
// "main" frame gameflix is built out of. The cart itself is fetched straight
// from tic80.com, which serves /cart/<hash>/<anything>.tic - so the play://
// path carries the hash as its folder and the cart's own file name as the ROM,
// and launch.tsv maps /TIC-80/ to https://tic80.com/cart/.
function generateTicLinks(romPath, imagePath) {
    var headers = document.querySelectorAll('.section-header');
    var foldername = headers.length ? headers[headers.length - 1].id : '';
    var base = encodeURI('play:///TIC-80/' + foldername);
    addFigureList(fileNames, function (fileName) {
        var [id, hash, nazov, subor] = fileName.split('\t');
        return { hash: hash, nazov: nazov, subor: subor };
    }, function (g) {
        // RetroArch picks the core by extension, and tic80.com has carts whose
        // file name carries none, so the name is only ever a label here - the
        // hash in the path is what identifies the cart.
        var rom = g.subor || g.hash;
        if (!/\.tic$/i.test(rom)) rom += '.tic';
        return figureHtml(`${base}/${g.hash}/${encodeURIComponent(rom)}`, `https://tic80.com/cart/${g.hash}/cover.gif`, g.nazov, g.nazov, ' rel="noreferrer"');
    });
}

function generateWasmLinks(romPath, imagePath) {
    romPath = romPath.replace("roms/WASM-4", "https://wasm4.org/play");
    addFigureList(fileNames, function (fileName) {
        var [subor, nazov] = fileName.split('\t');
        return { subor: subor, nazov: nazov };
    }, function (g) {
        return figureHtml(`${romPath}/${encodeURIComponent(g.subor)}`, `https://wasm4.org/carts/${g.subor}.png`, g.nazov, g.nazov);
    });
}

function generateLrNXLinks(romPath, imagePath) {
    romPath = romPath.replace("roms/LowresNX", "https://lowresnx.inutilis.com/topic.php?id=");
    addFigureList(fileNames, function (fileName) {
        var [subor, obrazok, nazov, id] = fileName.split('\t');
        return { obrazok: obrazok, nazov: nazov, id: id };
    }, function (g) {
        return figureHtml(`${romPath}${encodeURIComponent(g.id)}`, `https://lowresnx.inutilis.com/uploads/${g.obrazok}`, g.nazov, g.nazov);
    });
}

function generatePicoLinks(romPath, imagePath) {
    addFigureList(fileNames, function (fileName) {
        var [id, nazov, kart] = fileName.split('\t');
        return { nazov: nazov, kart: kart };
    }, function (g) {
        var screen = /^\d/.test(g.kart) ? "pico" + g.kart.replace(/\.p8\.png$/, '.png') : g.kart.replace(/^(.*)\.p8\.png$/, 'pico8_$1.png');
        var cart = g.kart.replace(/\.p8.png$/, "");
        return figureHtml(`https://www.lexaloffle.com/bbs/?pid=${cart}#p`, `https://www.lexaloffle.com/bbs/thumbs/${screen}`, g.nazov, g.nazov);
    });
}

function generateVoxLinks(romPath, imagePath) {
    addFigureList(fileNames, function (fileName) {
        var [id, nazov, kart] = fileName.split('\t');
        return { nazov: nazov, kart: kart };
    }, function (g) {
        var screen = g.kart.replace(/^(.*)\.vx\.png$/, 'vox_$1.png').replace(/^cpost/, "vox");
        var cart = g.kart.replace(/^cpost/, "").replace(/\.png$/, "");
        return figureHtml(`https://www.lexaloffle.com/bbs/?pid=${cart}#p`, `https://www.lexaloffle.com/bbs/thumbs/${screen}`, g.nazov, g.nazov);
    });
}

function generateFileLinks(romPath, imagePath) {
    var wrapInJavatari = false;
    var platform = location.pathname.split('/').pop().replace(/\.html?$/, '');
    var headers = document.querySelectorAll('.section-header');
    var foldername = headers.length ? headers[headers.length - 1].id : '';
    romPath = 'play:///' + platform + '/' + foldername;
    var encodedPath = encodeURI(romPath);
    addFigureList(fileNames, function (fileName) {
        var subor = fileName.includes("\t") ? fileName.split("\t")[0] : fileName;
        var nazov = fileName.includes("\t") ? fileName.split("\t")[1] : fileName.replace(/\.[^.]+$/, "");
        return { subor: subor, nazov: nazov };
    }, function (g) {
        var nameWithoutExt = g.subor.includes(".") ? g.subor.slice(0, g.subor.lastIndexOf(".")) : g.subor;
        var nameWithoutBrackets = nameWithoutExt.replace(/^([^)]*\([^)]*\)).*$/, "$1");
        var fileUrl = `${encodedPath}/${encodeURIComponent(g.subor)}`;
        var href = wrapInJavatari ? `https://javatari.org/?rom=${encodeURIComponent(fileUrl)}` : fileUrl;
        return figureHtml(href, `https://raw.githubusercontent.com/WizzardSK/${imagePath}/master/Named${gfThumbType}/${encodeURIComponent(nameWithoutBrackets)}.png`, nameWithoutExt, g.nazov, ' rel="noreferrer"');
    });
}
