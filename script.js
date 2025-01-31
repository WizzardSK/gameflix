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
        showHideProto.dispatchEvent(new Event('change'));
        showHideProgram.dispatchEvent(new Event('change'));
        showHideAlfa.dispatchEvent(new Event('change'));
        showHideBeta.dispatchEvent(new Event('change'));
        showHideDemo.dispatchEvent(new Event('change'));
        showHideAftermarket.dispatchEvent(new Event('change'));
        showHideUnl.dispatchEvent(new Event('change'));
        showHideAlt.dispatchEvent(new Event('change'));
        showHidePirate.dispatchEvent(new Event('change'));
        showHideBrackets.dispatchEvent(new Event('change'));
        showHidePrerelease.dispatchEvent(new Event('change'));
        showHideDisk.dispatchEvent(new Event('change'));
    }, 1000);
});

function handleCheckboxChange(checkbox, filterText) {
    checkbox.addEventListener('change', function () {
        for (let i = 0; i < figures.length; i++) {
            const caption = figures[i].getElementsByTagName('figcaption')[0];
            const captionText = caption.textContent.toLowerCase();
            if ((new RegExp(filterText).test(captionText)) && (new RegExp(filterInput.value.toLowerCase()).test(captionText))) { figures[i].style.display = checkbox.checked ? '' : 'none'; }
        }
        displayedCount = 0;
        for (let i = 0; i < figures.length; i++) { if (figures[i].style.display !== 'none') { displayedCount++; } }
        document.getElementById('pocet').innerHTML = " Games: " + displayedCount;
    });
}

handleCheckboxChange(showHideProto, "\\(proto\\)");
handleCheckboxChange(showHideProgram, "\\(program\\)");
handleCheckboxChange(showHideAlfa, "\\(alpha( [0-9]+)?\\)");
handleCheckboxChange(showHideBeta, "\\(beta( [0-9]+)?\\)");
handleCheckboxChange(showHideDemo, "\\(demo( [0-9]+)?\\)");
handleCheckboxChange(showHideAftermarket, "\\(aftermarket\\)");
handleCheckboxChange(showHideUnl, "\\(unl\\)");
handleCheckboxChange(showHideAlt, "\\(alt\\)");
handleCheckboxChange(showHidePirate, "\\(pirate\\)");
handleCheckboxChange(showHidePrerelease, "\\(pre-release\\)");
handleCheckboxChange(showHideBrackets, "\\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\\]");
handleCheckboxChange(showHideDisk, "\\(disk( [2-9B-Z].*)\\)");

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        filterInput.value = '';
        filterInput.dispatchEvent(new Event('input'));
        showHideProto.dispatchEvent(new Event('change'));
        showHideProgram.dispatchEvent(new Event('change'));
        showHideAlfa.dispatchEvent(new Event('change'));
        showHideBeta.dispatchEvent(new Event('change'));
        showHideDemo.dispatchEvent(new Event('change'));
        showHideAftermarket.dispatchEvent(new Event('change'));
        showHideUnl.dispatchEvent(new Event('change'));
        showHideAlt.dispatchEvent(new Event('change'));
        showHidePirate.dispatchEvent(new Event('change'));
        showHideBrackets.dispatchEvent(new Event('change'));
        showHidePrerelease.dispatchEvent(new Event('change'));
        showHideDisk.dispatchEvent(new Event('change'));
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
        'boxarts': { from: /_Snaps|_Titles|_Logos/g, to: '_Boxarts' },
        'snaps': { from: /_Boxarts|_Titles|_Logos/g, to: '_Snaps' },
        'titles': { from: /_Snaps|_Boxarts|_Logos/g, to: '_Titles' },
        'logos': { from: /_Snaps|_Boxarts|_Titles/g, to: '_Logos' }
    };
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].style.visibility = "visible";
        obrazky[i].src = obrazky[i].src.replace(replaceMap[operation].from, replaceMap[operation].to);
    }
}
function boxarts() { processImages('boxarts'); }
function snaps() { processImages('snaps'); }
function titles() { processImages('titles'); }
function logos() { processImages('logos'); }

function imgonerror(image) {
    image.src = image.src.replace("&", "_");
    image.onerror = function() { this.style.visibility = "hidden"; }
}
var obrazky = document.querySelectorAll("img");
for (var i = 0; i < obrazky.length; i++) { obrazky[i].onerror = function() { imgonerror(this); }; }
showHideProto.dispatchEvent(new Event('change'));
showHideProgram.dispatchEvent(new Event('change'));
showHideAlfa.dispatchEvent(new Event('change'));
showHideBeta.dispatchEvent(new Event('change'));
showHideDemo.dispatchEvent(new Event('change'));
showHideAftermarket.dispatchEvent(new Event('change'));
showHideUnl.dispatchEvent(new Event('change'));
showHideAlt.dispatchEvent(new Event('change'));
showHidePirate.dispatchEvent(new Event('change'));
showHideBrackets.dispatchEvent(new Event('change'));
showHidePrerelease.dispatchEvent(new Event('change'));
showHideDisk.dispatchEvent(new Event('change'));

document.addEventListener("DOMContentLoaded", function() {
    const images = document.querySelectorAll('img');
    images.forEach(image => {
        image.addEventListener('load', function() { image.classList.add('loaded'); });
        if (image.complete) { image.classList.add('loaded'); }
    });
});
