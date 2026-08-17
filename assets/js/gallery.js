/* First Step Preschool - gallery filter + lightbox (shared by Moments and Teacher Training galleries) */
(function () {
  'use strict';

  var FirstStep = window.FirstStep || (window.FirstStep = {});

  FirstStep.initFilter = function (opts) {
    var chips = document.querySelectorAll(opts.chips);
    var items = document.querySelectorAll(opts.items);
    var empty = document.querySelector(opts.empty);

    if (!chips.length || !items.length) return;

    function applyFilter(filter) {
      var visible = 0;
      items.forEach(function (item) {
        var match = filter === 'all' || item.getAttribute('data-category') === filter;
        item.classList.toggle('is-hidden', !match);
        if (match) visible++;
      });
      if (empty) empty.classList.toggle('is-hidden', visible !== 0);
      chips.forEach(function (chip) {
        var on = chip.getAttribute('data-filter') === filter;
        chip.classList.toggle('active', on);
        chip.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
    }

    chips.forEach(function (chip) {
      chip.addEventListener('click', function () {
        applyFilter(chip.getAttribute('data-filter'));
      });
    });

    applyFilter('all');
  };

  FirstStep.initLightbox = function (opts) {
    var items = Array.prototype.slice.call(document.querySelectorAll(opts.items));
    if (!items.length) return;

    var overlay = document.createElement('div');
    overlay.className = 'lightbox';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.innerHTML =
      '<button type="button" class="lightbox-close" aria-label="Close">' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"></path><path d="m6 6 12 12"></path></svg>' +
      '</button>' +
      '<button type="button" class="lightbox-prev" aria-label="Previous">' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"></path></svg>' +
      '</button>' +
      '<figure class="lightbox-figure">' +
      '<img src="" alt="" />' +
      '<figcaption class="lightbox-caption"></figcaption>' +
      '</figure>' +
      '<button type="button" class="lightbox-next" aria-label="Next">' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"></path></svg>' +
      '</button>';
    document.body.appendChild(overlay);

    var img = overlay.querySelector('img');
    var caption = overlay.querySelector('.lightbox-caption');
    var index = 0;

    function itemTitle(item) {
      var t = item.querySelector('.gallery-title');
      return t ? t.textContent : (item.getAttribute('data-title') || '');
    }

    function visibleItems() {
      return items.filter(function (it) {
        return !it.classList.contains('is-hidden');
      });
    }

    function show(i, list) {
      var item = list[i];
      if (!item) return;
      var title = itemTitle(item);
      img.src = item.getAttribute('data-full');
      img.alt = title;
      caption.textContent = title;
      overlay.classList.add('open');
      document.body.classList.add('lightbox-open');
      overlay.setAttribute('aria-hidden', 'false');
    }

    function open(idx) {
      var list = visibleItems();
      index = list.indexOf(items[idx]);
      if (index === -1) index = 0;
      show(index, list);
    }

    function next() {
      var list = visibleItems();
      index = (index + 1) % list.length;
      show(index, list);
    }

    function prev() {
      var list = visibleItems();
      index = (index - 1 + list.length) % list.length;
      show(index, list);
    }

    function close() {
      overlay.classList.remove('open');
      document.body.classList.remove('lightbox-open');
      overlay.setAttribute('aria-hidden', 'true');
      img.removeAttribute('src');
    }

    items.forEach(function (item, i) {
      item.addEventListener('click', function (e) {
        e.preventDefault();
        open(i);
      });
    });

    overlay.querySelector('.lightbox-close').addEventListener('click', close);
    overlay.querySelector('.lightbox-prev').addEventListener('click', prev);
    overlay.querySelector('.lightbox-next').addEventListener('click', next);
    overlay.addEventListener('click', function (e) {
      if (e.target === overlay) close();
    });
    document.addEventListener('keydown', function (e) {
      if (!overlay.classList.contains('open')) return;
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowRight') next();
      if (e.key === 'ArrowLeft') prev();
    });
  };

  // Auto-initialise any filter container present on the page
  document.querySelectorAll('[data-gallery-filter]').forEach(function (container) {
    FirstStep.initFilter({
      chips: '.chip',
      items: container.getAttribute('data-items') || '.gallery-item',
      empty: container.getAttribute('data-empty') || null
    });
  });

  // Auto-initialise lightboxes
  document.querySelectorAll('[data-lightbox]').forEach(function () {
    FirstStep.initLightbox({ items: '.gallery-item' });
  });
})();
