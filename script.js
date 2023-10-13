const filterInput = document.getElementById('filterInput');
const figureList = document.getElementById('figureList');
const figures = figureList.getElementsByTagName('figure');
var size = 160;
filterInput.focus();
let timerId;
filterInput.addEventListener('input', function () {
    clearTimeout(timerId);
    const filterText = filterInput.value.toLowerCase();
    timerId = setTimeout(function() {
        for (let i = 0; i < figures.length; i++) {
            const caption = figures[i].getElementsByTagName('figcaption')[0];
            const captionText = caption.textContent.toLowerCase();
            if (captionText.includes(filterText)) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; }
        }
        showHideBeta.dispatchEvent(new Event('change'));
        showHideDemo.dispatchEvent(new Event('change'));
        showHideAftermarket.dispatchEvent(new Event('change'));
        showHideProto.dispatchEvent(new Event('change'));
        showHideUnl.dispatchEvent(new Event('change'));
        showHideProgram.dispatchEvent(new Event('change'));
        showHideAlt.dispatchEvent(new Event('change'));
        showHidePirate.dispatchEvent(new Event('change'));
        showHideBrackets.dispatchEvent(new Event('change'));
    }, 1000);
});

function handleCheckboxChange(checkbox, filterText) {
    checkbox.addEventListener('change', function () {
        for (let i = 0; i < figures.length; i++) {
            const caption = figures[i].getElementsByTagName('figcaption')[0];
            const captionText = caption.textContent.toLowerCase();
            if ((captionText.includes(filterText)) && (captionText.includes(filterInput.value.toLowerCase()))) { figures[i].style.display = checkbox.checked ? '' : 'none'; }
        }
        displayedCount = 0;
        for (let i = 0; i < figures.length; i++) { if (figures[i].style.display !== 'none') { displayedCount++; } }
        document.getElementById('pocet').innerHTML = " Games: " + displayedCount;
    });
}
handleCheckboxChange(showHideBeta, "(beta");
handleCheckboxChange(showHideDemo, "(demo");
handleCheckboxChange(showHideAftermarket, "(aftermarket");
handleCheckboxChange(showHideProto, "(proto");
handleCheckboxChange(showHideUnl, "(unl");
handleCheckboxChange(showHideProgram, "(program");
handleCheckboxChange(showHideAlt, "(alt");
handleCheckboxChange(showHidePirate, "(pirate");
handleCheckboxChange(showHideBrackets, "[");

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        filterInput.value = '';
        filterInput.dispatchEvent(new Event('input'));
        showHideBeta.dispatchEvent(new Event('change'));
        showHideDemo.dispatchEvent(new Event('change'));
        showHideAftermarket.dispatchEvent(new Event('change'));
        showHideProto.dispatchEvent(new Event('change'));
        showHideUnl.dispatchEvent(new Event('change'));
        showHideProgram.dispatchEvent(new Event('change'));
        showHideAlt.dispatchEvent(new Event('change'));
        showHidePirate.dispatchEvent(new Event('change'));
        showHideBrackets.dispatchEvent(new Event('change'));
    } else { filterInput.focus(); }
});

function changeSize(size) {
    var obrazky = document.getElementsByTagName('img');
    var figurky = document.getElementsByTagName('figure');
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].style.width = size;
        obrazky[i].style.height = (size / 1.333) + 'px';
        figurky[i].style.width = size;
        figurky[i].style.height = size + 'px';
        figurky[i].style.fontSize = Math.round(size / 13.3) + 'px';
    }
}
function change80() { changeSize(80); }
function change120() { changeSize(120); }
function change160() { changeSize(160); }
function change240() { changeSize(240); }
function change320() { changeSize(320); }

function processImages(operation) {
    var obrazky = document.getElementsByTagName('img');
    var replaceMap = {
        'boxarts': { from: /_Snaps|_Titles/g, to: '_Boxarts' },
        'snaps': { from: /_Boxarts|_Titles/g, to: '_Snaps' },
        'titles': { from: /_Snaps|_Boxarts/g, to: '_Titles' }
    };
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].style.visibility = "visible";
        obrazky[i].src = obrazky[i].src.replace(replaceMap[operation].from, replaceMap[operation].to);
    }
}
function boxarts() { processImages('boxarts'); }
function snaps() { processImages('snaps'); }
function titles() { processImages('titles'); }

function imgonerror(image) {
    image.src = image.src.replace("&", "_");
    image.onerror = function() { this.style.visibility = "hidden"; }
}
var obrazky = document.querySelectorAll("img");
for (var i = 0; i < obrazky.length; i++) { obrazky[i].onerror = function() { imgonerror(this); }; }
showHideBeta.dispatchEvent(new Event('change'));
showHideDemo.dispatchEvent(new Event('change'));
showHideAftermarket.dispatchEvent(new Event('change'));
showHideProto.dispatchEvent(new Event('change'));
showHideUnl.dispatchEvent(new Event('change'));
showHideProgram.dispatchEvent(new Event('change'));
showHideAlt.dispatchEvent(new Event('change'));
showHidePirate.dispatchEvent(new Event('change'));
showHideBrackets.dispatchEvent(new Event('change'));
