const filterInput = document.getElementById('filterInput');
const figures = document.querySelectorAll('.figureList figure');
const pocetEl = document.getElementById('pocet');
filterInput.focus();

// Cache figcaption texts for faster filtering
const captionTexts = [];
for (let i = 0; i < figures.length; i++) {
    captionTexts.push(figures[i].getElementsByTagName('figcaption')[0].textContent.toLowerCase());
}

// Navlinks
var navlinksDiv = document.getElementById('navlinks');
var sectionHeaders = document.querySelectorAll('.section-header');

if (sectionHeaders.length > 1 && navlinksDiv) {
    sectionHeaders.forEach(function(header) {
        var link = document.createElement('a');
        link.href = '#';
        link.textContent = header.id;
        link.className = 'navlink';
        link.addEventListener('click', function(e) {
            e.preventDefault();
            var topbarHeight = document.getElementById('topbar').offsetHeight;
            var headerTop = header.getBoundingClientRect().top + window.scrollY;
            window.scrollTo({ top: headerTop - topbarHeight, behavior: 'smooth' });
        });
        navlinksDiv.appendChild(link);
    });
}

// Push first section header below the fixed topbar (after navlinks are added)
if (sectionHeaders.length > 0) {
    sectionHeaders[0].style.marginTop = document.getElementById('topbar').offsetHeight + 'px';
}

// Checkbox definitions
var checkboxes = [
    [showHideProto, /\(proto\)/],
    [showHideProgram, /\(program\)/],
    [showHideAlfa, /\(alpha( [0-9]+)?\)/],
    [showHideBeta, /\(beta( [0-9]+)?\)/],
    [showHideDemo, /\(demo( [0-9]+)?\)/],
    [showHideAftermarket, /\(aftermarket\)/],
    [showHideUnl, /\(unl\)/],
    [showHideAlt, /\(alt|alternate\)/],
    [showHidePirate, /\(pirate\)/],
    [showHidePrerelease, /\(pre-release\)/],
    [showHideBrackets, /\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|[Hh] [^\]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]/],
    [showHideDisk, /\((disk|side)( [2-9b-z].*)\)/]
];

function fireAllCheckboxes() {
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i][0].dispatchEvent(new Event('change'));
    }
}

function updateCount() {
    var count = 0;
    for (var i = 0; i < figures.length; i++) {
        if (figures[i].style.display !== 'none') count++;
    }
    pocetEl.innerHTML = count + "/" + figures.length;
}

// Filter input with debounce
var timerId;
filterInput.addEventListener('input', function () {
    clearTimeout(timerId);
    var filterText = filterInput.value.toLowerCase();
    timerId = setTimeout(function() {
        for (var i = 0; i < figures.length; i++) {
            figures[i].style.display = captionTexts[i].includes(filterText) ? '' : 'none';
        }
        fireAllCheckboxes();
    }, 1000);
});

// Checkbox change handlers with pre-compiled regex
for (var c = 0; c < checkboxes.length; c++) {
    (function(checkbox, regex) {
        checkbox.addEventListener('change', function () {
            var filterText = filterInput.value.toLowerCase();
            for (var i = 0; i < figures.length; i++) {
                if (regex.test(captionTexts[i]) && captionTexts[i].includes(filterText)) {
                    figures[i].style.display = checkbox.checked ? '' : 'none';
                }
            }
            updateCount();
        });
    })(checkboxes[c][0], checkboxes[c][1]);
}

// Escape key resets filter
document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        filterInput.value = '';
        filterInput.dispatchEvent(new Event('input'));
        fireAllCheckboxes();
    } else { filterInput.focus(); }
});

// Size change
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

// Image type switching
var replaceMap = {
    'boxarts': { from: /_Snaps|_Titles|_Logos/g, to: '_Boxarts' },
    'snaps': { from: /_Boxarts|_Titles|_Logos/g, to: '_Snaps' },
    'titles': { from: /_Snaps|_Boxarts|_Logos/g, to: '_Titles' },
    'logos': { from: /_Snaps|_Boxarts|_Titles/g, to: '_Logos' }
};
function processImages(operation) {
    var obrazky = document.getElementsByTagName('img');
    var map = replaceMap[operation];
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].style.visibility = "visible";
        obrazky[i].src = obrazky[i].src.replace(map.from, map.to);
    }
}
function boxarts() { processImages('boxarts'); }
function snaps() { processImages('snaps'); }
function titles() { processImages('titles'); }
function logos() { processImages('logos'); }

// Image error handling + loaded class (merged from script2.js)
var obrazky = document.querySelectorAll("img");
for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].onerror = function() { this.style.visibility = "hidden"; };
    if (obrazky[i].complete) { obrazky[i].classList.add('loaded'); }
    else { obrazky[i].addEventListener('load', function() { this.classList.add('loaded'); }); }
}

// Initial checkbox state
fireAllCheckboxes();
