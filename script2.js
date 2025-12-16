document.addEventListener("DOMContentLoaded", function() {
    const images = document.querySelectorAll('img');
    images.forEach(image => {
        image.addEventListener('load', function() { image.classList.add('loaded'); });
        if (image.complete) { image.classList.add('loaded'); }
    });
});
