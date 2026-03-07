var filterInput = document.getElementById('filterInput');
var isSystems = filterInput && !document.getElementById('topbar');

if (isSystems) {
    // Systems sidebar: filter links + main frame figures
    filterInput.focus();
    var links = document.querySelectorAll('a[target="main"]');
    var timerId;
    filterInput.addEventListener('input', function() {
        clearTimeout(timerId);
        timerId = setTimeout(function() {
            var text = filterInput.value.toLowerCase();
            // Filter links and hide siblings (small, br, text nodes)
            links.forEach(function(a) {
                var visible = a.textContent.toLowerCase().includes(text);
                a.style.display = visible ? '' : 'none';
                var el = a.nextSibling;
                while (el && el.tagName !== 'A' && el.tagName !== 'B') {
                    if (el.style) el.style.display = visible ? '' : 'none';
                    el = el.nextSibling;
                }
            });
            // Hide section headers with no visible links + surrounding br
            var headers = document.querySelectorAll('b');
            headers.forEach(function(b) {
                var hasVisible = false;
                var el = b.nextSibling;
                while (el && el.tagName !== 'B') {
                    if (el.tagName === 'A' && el.style.display !== 'none') { hasVisible = true; break; }
                    el = el.nextSibling;
                }
                var show = hasVisible || !text;
                b.style.display = show ? '' : 'none';
                // Hide br before and after header
                var prev = b.previousSibling;
                while (prev && (prev.tagName === 'BR' || (prev.nodeType === 3 && !prev.textContent.trim()))) {
                    if (prev.style) prev.style.display = show ? '' : 'none';
                    prev = prev.previousSibling;
                }
                var next = b.nextSibling;
                if (next && next.tagName === 'BR') next.style.display = show ? '' : 'none';
            });
            // Filter main frame figures and headers
            try {
                var mainDoc = parent.frames['main'].document;
                var figures = mainDoc.querySelectorAll('figure');
                for (var i = 0; i < figures.length; i++) {
                    figures[i].style.display = figures[i].textContent.toLowerCase().includes(text) ? '' : 'none';
                }
                var mainHeaders = mainDoc.querySelectorAll('.section-header');
                mainHeaders.forEach(function(h) {
                    var hasVisible = false;
                    var el = h.nextElementSibling;
                    while (el && !el.classList.contains('section-header')) {
                        if (el.tagName === 'FIGURE' && el.style.display !== 'none') { hasVisible = true; break; }
                        el = el.nextElementSibling;
                    }
                    h.style.display = hasVisible || !text ? '' : 'none';
                });
            } catch(e) {}
        }, 500);
    });
    filterInput.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') { filterInput.value = ''; filterInput.dispatchEvent(new Event('input')); }
    });
} else {
    // Main page or platform page
    var isMain = !document.querySelector('.figureList');
    var figures = document.querySelectorAll(isMain ? 'figure' : '.figureList figure');
    var pocetEl = document.getElementById('pocet');
    if (filterInput) { window.focus(); filterInput.focus(); }
    else if (isMain) { try { parent.frames['menu'].document.getElementById('filterInput').focus(); } catch(e) {} }

    var captionTexts = new Array(figures.length);
    for (var i = 0; i < figures.length; i++) {
        captionTexts[i] = (isMain ? figures[i].textContent : figures[i].getElementsByTagName('figcaption')[0].textContent).toLowerCase();
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

    // Push first content below the fixed topbar (after layout settles)
    var topbar = document.getElementById('topbar');
    if (topbar) {
        function adjustTopMargin() {
            var h = topbar.offsetHeight + 'px';
            if (sectionHeaders.length > 0) {
                sectionHeaders[0].style.marginTop = h;
            } else {
                var firstList = document.querySelector('.figureList');
                if (firstList) firstList.style.marginTop = h;
            }
        }
        adjustTopMargin();
        requestAnimationFrame(adjustTopMargin);
    }

    // Checkbox definitions (platform pages only)
    var checkboxes = [];
    if (!isMain && filterInput) {
        checkboxes = [
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
    }

    function applyFilters() {
        var filterText = filterInput ? filterInput.value.toLowerCase() : '';
        var count = 0;
        for (var i = 0; i < figures.length; i++) {
            var text = captionTexts[i];
            var visible = text.includes(filterText);
            if (visible) {
                for (var c = 0; c < checkboxes.length; c++) {
                    if (!checkboxes[c][0].checked && checkboxes[c][1].test(text)) {
                        visible = false;
                        break;
                    }
                }
            }
            figures[i].style.display = visible ? '' : 'none';
            if (visible) count++;
        }
        if (pocetEl) pocetEl.innerHTML = count + "/" + figures.length;
    }

    if (filterInput) {
        var timerId;
        filterInput.addEventListener('input', function () {
            clearTimeout(timerId);
            timerId = setTimeout(applyFilters, 500);
        });
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                filterInput.value = '';
                applyFilters();
            } else { filterInput.focus(); }
        });
    }

    for (var c = 0; c < checkboxes.length; c++) {
        checkboxes[c][0].addEventListener('change', applyFilters);
    }

    // Size change
    function changeSize(size) {
        var figurky = document.querySelectorAll('.figureList figure');
        var h = (size / 1.333) + 'px';
        var fs = Math.round(size / 13.3) + 'px';
        for (var i = 0; i < figurky.length; i++) {
            figurky[i].style.width = size;
            figurky[i].style.height = size + 'px';
            figurky[i].style.fontSize = fs;
            figurky[i].querySelector('img').style.width = size;
            figurky[i].querySelector('img').style.height = h;
        }
    }

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

    // Image error handling + loaded class
    var obrazky = document.querySelectorAll("img");
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].onerror = function() { this.style.visibility = "hidden"; };
        if (obrazky[i].complete) { obrazky[i].classList.add('loaded'); }
        else { obrazky[i].addEventListener('load', function() { this.classList.add('loaded'); }); }
    }

    applyFilters();
}
