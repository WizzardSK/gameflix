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
            // Filter links and hide siblings (small, text nodes, br after small)
            links.forEach(function(a) {
                var visible = a.textContent.toLowerCase().includes(text);
                a.style.display = visible ? '' : 'none';
                var el = a.nextSibling;
                while (el && el.tagName !== 'A' && el.tagName !== 'B') {
                    if (el.style) el.style.display = visible ? '' : 'none';
                    if (el.tagName === 'BR') break;
                    el = el.nextSibling;
                }
            });
            // Hide section headers with no visible links
            var headers = document.querySelectorAll('b');
            var firstVisible = true;
            headers.forEach(function(b) {
                var hasVisible = false;
                var el = b.nextSibling;
                while (el && el.tagName !== 'B') {
                    if (el.tagName === 'A' && el.style.display !== 'none') { hasVisible = true; break; }
                    el = el.nextSibling;
                }
                var show = hasVisible || !text;
                b.style.display = show ? '' : 'none';
                // Hide br before header: always hide for first visible, show for others
                var prev = b.previousSibling;
                if (prev && prev.tagName === 'BR') {
                    prev.style.display = (show && !firstVisible) ? '' : 'none';
                    var prev2 = prev.previousSibling;
                    if (prev2 && prev2.tagName === 'BR') prev2.style.display = 'none';
                }
                // Hide br after header when hidden
                var next = b.nextSibling;
                if (next && next.tagName === 'BR') next.style.display = show ? '' : 'none';
                if (show) firstVisible = false;
            });
            // Filter main frame figures and headers (only on main page, not platform pages)
            try {
                var mainDoc = parent.frames['main'].document;
                if (mainDoc.querySelector('.figureList')) throw 0;
                var figures = mainDoc.querySelectorAll('figure');
                for (var i = 0; i < figures.length; i++) {
                    figures[i].style.display = figures[i].textContent.toLowerCase().includes(text) ? '' : 'none';
                }
                var mainHeaders = mainDoc.querySelectorAll('.section-header');
                var topbar = mainDoc.getElementById('topbar');
                var topMargin = topbar ? topbar.offsetHeight + 'px' : '0';
                var firstVisible = true;
                mainHeaders.forEach(function(h, idx) {
                    var hasVisible = false;
                    var next = mainHeaders[idx + 1];
                    var el = h.nextElementSibling;
                    while (el && el !== next) {
                        if (el.tagName === 'FIGURE' && el.style.display !== 'none') { hasVisible = true; break; }
                        el = el.nextElementSibling;
                    }
                    var show = hasVisible || !text;
                    h.style.display = show ? '' : 'none';
                    h.style.marginTop = (show && firstVisible) ? topMargin : '0';
                    if (show) firstVisible = false;
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
    // Platform pages register their games in gfLists (platform.js) and only the
    // rows on screen exist as elements; the main page is plain HTML.
    var lists = typeof gfLists !== 'undefined' ? gfLists : [];
    var virtual = lists.length > 0;
    var figures = virtual ? [] : document.querySelectorAll(isMain ? 'figure' : '.figureList figure');
    var pocetEl = document.getElementById('pocet');
    if (filterInput) { window.focus(); filterInput.focus(); }
    else if (isMain) { try { parent.frames['menu'].document.getElementById('filterInput').focus(); } catch(e) {} }

    var captionTexts = new Array(figures.length);
    for (var i = 0; i < figures.length; i++) {
        captionTexts[i] = (isMain ? figures[i].textContent : figures[i].getElementsByTagName('figcaption')[0].textContent).toLowerCase();
    }

    // ---- Windowed rendering of the game lists --------------------------------
    var itemSize = 160;   // figure width and height, changed by changeSize()
    var ITEM_GAP = 4;     // horizontal gap between figures
    var ROW_BUFFER = 4;   // rows rendered above and below the viewport
    lists.forEach(function(l, k) {
        l.el = document.querySelector('.figureList[data-list="' + k + '"]');
        l.rows = document.createElement('div');
        l.rows.className = 'figureRows';
        l.el.appendChild(l.rows);
        l.shown = null;   // indices passing the filter
        l.first = l.last = -2;   // rendered row range; -1/-1 = nothing rendered
    });

    function layoutLists() {
        // Two passes: setting the heights can add or remove the scrollbar,
        // which changes the width the columns are computed from.
        for (var pass = 0; pass < 2; pass++) {
            var changed = false;
            for (var k = 0; k < lists.length; k++) {
                var l = lists[k];
                var cols = Math.max(1, Math.floor((l.el.clientWidth + ITEM_GAP) / (itemSize + ITEM_GAP)));
                if (pass && cols === l.cols) continue;
                changed = true;
                l.cols = cols;
                l.el.style.height = Math.ceil(l.shown.length / cols) * itemSize + 'px';
                l.rows.style.gridTemplateColumns = 'repeat(' + cols + ', ' + itemSize + 'px)';
                l.rows.style.gridAutoRows = itemSize + 'px';
                l.first = l.last = -2;   // force a re-render, even of a list that is now empty
            }
            if (!changed) break;
        }
        renderLists();
    }

    function renderLists() {
        var viewH = window.innerHeight;
        for (var k = 0; k < lists.length; k++) {
            var l = lists[k];
            var top = l.el.getBoundingClientRect().top;
            var rowCount = Math.ceil(l.shown.length / l.cols);
            var first = Math.max(0, Math.floor(-top / itemSize) - ROW_BUFFER);
            var last = Math.min(rowCount - 1, Math.floor((viewH - top) / itemSize) + ROW_BUFFER);
            if (first > last) first = last = -1;
            if (first === l.first && last === l.last) continue;
            l.first = first; l.last = last;
            var html = [];
            if (first >= 0) {
                var end = Math.min(l.shown.length, (last + 1) * l.cols);
                for (var i = first * l.cols; i < end; i++) html.push(l.render(l.shown[i]));
            }
            l.rows.style.top = Math.max(first, 0) * itemSize + 'px';
            l.rows.innerHTML = html.join('');
            // Thumbnails already in the cache skip the fade-in when scrolled back to
            var imgs = l.rows.getElementsByTagName('img');
            for (var j = 0; j < imgs.length; j++) {
                if (imgs[j].complete && imgs[j].naturalWidth) imgs[j].classList.add('loaded');
            }
        }
    }

    if (virtual) {
        var renderQueued = false;
        var queueRender = function() {
            if (renderQueued) return;
            renderQueued = true;
            requestAnimationFrame(function() { renderQueued = false; renderLists(); });
        };
        window.addEventListener('scroll', queueRender, { passive: true });
        window.addEventListener('resize', function() { requestAnimationFrame(layoutLists); });
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
            if (header.dataset.count) {
                var sm = document.createElement('small');
                sm.textContent = ' ' + header.dataset.count;
                link.appendChild(sm);
            }
            link.addEventListener('click', function(e) {
                e.preventDefault();
                var topbarHeight = document.getElementById('topbar').offsetHeight;
                var headerTop = header.getBoundingClientRect().top + window.scrollY;
                window.scrollTo({ top: headerTop - topbarHeight, behavior: 'smooth' });
            });
            navlinksDiv.appendChild(link);
        });
    }

    // Push content below the fixed topbar
    var topbar = document.getElementById('topbar');
    if (topbar) {
        var target = sectionHeaders.length > 0 ? sectionHeaders[0] : document.querySelector('.figureList');
        if (target) {
            function adjustTopMargin() { target.style.marginTop = topbar.offsetHeight + 'px'; }
            adjustTopMargin();
            new ResizeObserver(adjustTopMargin).observe(topbar);
        }
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

    function passesCheckboxes(text) {
        for (var c = 0; c < checkboxes.length; c++) {
            if (!checkboxes[c][0].checked && checkboxes[c][1].test(text)) return false;
        }
        return true;
    }

    function applyFilters() {
        var filterText = filterInput ? filterInput.value.toLowerCase() : '';
        var count = 0;
        if (virtual) {
            var total = 0;
            for (var k = 0; k < lists.length; k++) {
                var captions = lists[k].captions, shown = [];
                for (var i = 0; i < captions.length; i++) {
                    if (captions[i].includes(filterText) && passesCheckboxes(captions[i])) shown.push(i);
                }
                lists[k].shown = shown;
                count += shown.length;
                total += captions.length;
            }
            if (pocetEl) pocetEl.innerHTML = count + "/" + total;
            layoutLists();
            return;
        }
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
            var display = visible ? '' : 'none';
            if (figures[i].style.display !== display) figures[i].style.display = display;
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

    // Size change: one stylesheet rule instead of inline styles on every figure,
    // so a list of tens of thousands of games is restyled in a single pass
    var sizeStyle = document.createElement('style');
    document.head.appendChild(sizeStyle);
    function changeSize(size) {
        itemSize = size;
        sizeStyle.textContent = '.figureList figure { width: ' + size + 'px; height: ' + size + 'px; font-size: ' + Math.round(size / 13.3) + 'px }' +
            '.figureList figure img { width: ' + size + 'px; height: ' + (size / 1.333) + 'px }';
        if (virtual) layoutLists();
    }

    // Image type switching
    var replaceMap = {
        'boxarts': { from: /_Snaps|_Titles|_Logos/g, to: '_Boxarts' },
        'snaps': { from: /_Boxarts|_Titles|_Logos/g, to: '_Snaps' },
        'titles': { from: /_Snaps|_Boxarts|_Logos/g, to: '_Titles' },
        'logos': { from: /_Snaps|_Boxarts|_Titles/g, to: '_Logos' }
    };
    function processImages(operation) {
        var map = replaceMap[operation];
        if (virtual) {
            gfThumbType = map.to;
            layoutLists();
            return;
        }
        var obrazky = document.getElementsByTagName('img');
        for (var i = 0; i < obrazky.length; i++) {
            obrazky[i].style.visibility = "visible";
            obrazky[i].src = obrazky[i].src.replace(map.from, map.to);
        }
    }

    // Image error handling + loaded class. load/error do not bubble, so catch
    // them in the capture phase once instead of adding two listeners per image.
    document.addEventListener('load', function(e) { if (e.target.tagName === 'IMG') e.target.classList.add('loaded'); }, true);
    document.addEventListener('error', function(e) { if (e.target.tagName === 'IMG') e.target.style.visibility = 'hidden'; }, true);
    var obrazky = document.querySelectorAll("img");
    for (var i = 0; i < obrazky.length; i++) {
        if (obrazky[i].complete && obrazky[i].naturalWidth) obrazky[i].classList.add('loaded');
    }

    applyFilters();
}
