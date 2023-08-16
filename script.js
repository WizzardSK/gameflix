const filterInput = document.getElementById('filterInput');
const figureList = document.getElementById('figureList');
const figures = figureList.getElementsByTagName('figure');
filterInput.focus();
filterInput.addEventListener('input', function () {
    const filterText = filterInput.value.toLowerCase();
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; }
    }
});
showHideBeta.addEventListener('change', function () {
    const filterText = "(beta";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideBeta.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideDemo.addEventListener('change', function () {
    const filterText = "(demo";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideDemo.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideAftermarket.addEventListener('change', function () {
    const filterText = "(aftermarket";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideAftermarket.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideProto.addEventListener('change', function () {
    const filterText = "(proto";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideProto.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideUnl.addEventListener('change', function () {
    const filterText = "(unl";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideUnl.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideProgram.addEventListener('change', function () {
    const filterText = "(program";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideProgram.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHideAlt.addEventListener('change', function () {
    const filterText = "(alt";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHideAlt.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
showHidePirate.addEventListener('change', function () {
    const filterText = "(pirate";
    for (let i = 0; i < figures.length; i++) {
        const caption = figures[i].getElementsByTagName('figcaption')[0]; const captionText = caption.textContent.toLowerCase();
        if (captionText.includes(filterText)) { if (showHidePirate.checked) { figures[i].style.display = ''; } else { figures[i].style.display = 'none'; } }
    }
});
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
    } else {
        filterInput.focus();
    }
});
function change80() {
  var obrazky = document.getElementsByTagName('img');
  var figurky = document.getElementsByTagName('figure');
  for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].style.width = '80px';
    obrazky[i].style.height = '60px';
    figurky[i].style.width = '80px';
    figurky[i].style.height = '80px';
    figurky[i].style.fontSize = '8px';
  }
}
function change120() {
  var obrazky = document.getElementsByTagName('img');
  var figurky = document.getElementsByTagName('figure');
  for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].style.width = '120px';
    obrazky[i].style.height = '90px';
    figurky[i].style.width = '120px';
    figurky[i].style.height = '120px';
    figurky[i].style.fontSize = '10px';
  }
}
function change160() {
  var obrazky = document.getElementsByTagName('img');
  var figurky = document.getElementsByTagName('figure');
  for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].style.width = '160px';
    obrazky[i].style.height = '120px';
    figurky[i].style.width = '160px';
    figurky[i].style.height = '160px';
    figurky[i].style.fontSize = '12px';
  }
}
function change240() {
  var obrazky = document.getElementsByTagName('img');
  var figurky = document.getElementsByTagName('figure');
  for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].style.width = '240px';
    obrazky[i].style.height = '180px';
    figurky[i].style.width = '240px';
    figurky[i].style.height = '240px';
    figurky[i].style.fontSize = '14px';
  }
}
function change320() {
  var obrazky = document.getElementsByTagName('img');
  var figurky = document.getElementsByTagName('figure');
  for (var i = 0; i < obrazky.length; i++) {
    obrazky[i].style.width = '320px';
    obrazky[i].style.height = '240px';
    figurky[i].style.width = '320px';
    figurky[i].style.height = '320px';
    figurky[i].style.fontSize = '16px';
  }
}
function boxarts() {
    var obrazky = document.getElementsByTagName('img');
    var figurky = document.getElementsByTagName('figure');
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].src = obrazky[i].src.replace(/_Snaps|_Titles/g, '_Boxarts');
    }
}
function snaps() {
    var obrazky = document.getElementsByTagName('img');
    var figurky = document.getElementsByTagName('figure');
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].src = obrazky[i].src.replace(/_Boxarts|_Titles/g, '_Snaps');
    }
}
function titles() {
    var obrazky = document.getElementsByTagName('img');
    var figurky = document.getElementsByTagName('figure');
    for (var i = 0; i < obrazky.length; i++) {
        obrazky[i].src = obrazky[i].src.replace(/_Snaps|_Boxarts/g, '_Titles');
    }
}
showHideBeta.dispatchEvent(new Event('change'));
showHideDemo.dispatchEvent(new Event('change'));
showHideAftermarket.dispatchEvent(new Event('change'));
showHideProto.dispatchEvent(new Event('change'));
showHideUnl.dispatchEvent(new Event('change'));
showHideProgram.dispatchEvent(new Event('change'));
showHideAlt.dispatchEvent(new Event('change'));
showHidePirate.dispatchEvent(new Event('change'));
