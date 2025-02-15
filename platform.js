let text = `<div id=\"topbar\"><link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
<input type=\"text\" id=\"filterInput\" placeholder=\"Filter...\"><span id=\"pocet\"></span>
<input type=\"radio\" name=\"thumbtype\" id=\"Snaps\" value=\"Snaps\" checked onclick=\"snaps()\"><label for=\"Snaps\">Snaps</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Titles\" value=\"Titles\" onclick=\"titles()\"><label for=\"Titles\">Titles</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Boxarts\" value=\"Boxarts\" onclick=\"boxarts()\"><label for=\"Boxarts\">Boxarts</label>
<input type=\"radio\" name=\"thumbtype\" id=\"Logos\" value=\"Logos\" onclick=\"logos()\"><label for=\"Logos\">Logos</label>
<input type=\"radio\" name=\"size\" id=\"80px\" value=\"80px\" onclick=\"change80()\"><label for=\"80px\">80px</label>
<input type=\"radio\" name=\"size\" id=\"120px\" value=\"120px\" onclick=\"change120()\"><label for=\"120px\">120px</label>
<input type=\"radio\" name=\"size\" id=\"160px\" value=\"160px\" onclick=\"change160()\" checked><label for=\"160px\">160px</label>
<input type=\"radio\" name=\"size\" id=\"240px\" value=\"240px\" onclick=\"change240()\"><label for=\"240px\">240px</label>
<input type=\"radio\" name=\"size\" id=\"320px\" value=\"320px\" onclick=\"change320()\"><label for=\"320px\">320px</label>
<br />
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
<input type=\"checkbox\" id=\"showHideDisk\"><label for=\"showHideDisk\">[disk 2]</label>
</div><br><br><br><div id=\"figureList\">`;

document.write(text);

document.addEventListener("DOMContentLoaded", function() {
    if (location.protocol !== "file:") { document.querySelectorAll("a").forEach(link => { link.addEventListener("click", function(event) { event.preventDefault(); }); }); }
});

function generateFileLinks(romPath, imagePath) {
    fileNames.forEach(fileName => {
        const nameWithoutExt = fileName.slice(0, fileName.lastIndexOf(".")) || fileName;
        document.write(`<a href="../${romPath}/${fileName}" target="main">
        <figure><img loading="lazy" src="https://raw.githubusercontent.com/WizzardSK/${imagePath}/master/Named_Snaps/${nameWithoutExt}.png" alt="${fileName}"><figcaption>${fileName}</figcaption></figure></a>`);
    });
}

function bgImage(platform) {
    document.write(`<style> figure { background-image: url('https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${platform}.png'); } </style>`);
}
