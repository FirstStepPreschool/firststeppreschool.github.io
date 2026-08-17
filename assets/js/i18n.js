/* First Step Preschool - language switching (English / Hindi / Marathi) */
(function () {
  'use strict';

  var STORAGE_KEY = 'firststep.lang';
  var DEFAULT_LANG = 'en';
  var SUPPORTED = { en: 'English', hi: 'हिन्दी', mr: 'मराठी' };

  var current = DEFAULT_LANG;
  var dict = {};           // translations for current language
  var english = {};        // cached English (fallback reference)
  var pending = [];        // elements waiting for dictionary
  var pageId = document.body.getAttribute('data-page') || 'home';

  function basePath() {
    return document.body.getAttribute('data-base') || '';
  }

  function loadLanguage(lang) {
    if (typeof english[lang] === 'undefined') {
      fetch(basePath() + 'translations/' + lang + '.json')
        .then(function (r) {
          if (!r.ok) throw new Error('not found');
          return r.json();
        })
        .then(function (data) {
          english[lang] = data;
          if (current === lang) apply();
        })
        .catch(function () {
          english[lang] = null;
          if (current === lang) apply();
        });
    } else {
      apply();
    }
  }

  function setLanguage(lang, persist) {
    if (!SUPPORTED[lang]) lang = DEFAULT_LANG;
    current = lang;
    document.documentElement.setAttribute('lang', lang);
    if (persist !== false) {
      try { localStorage.setItem(STORAGE_KEY, lang); } catch (e) {}
    }
    loadLanguage(lang);
  }

  function apply() {
    var data = english[current];
    if (current !== 'en' && data === undefined) return; // still loading
    if (data === null) data = {}; // language file missing -> fallback to HTML text

    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      var value = lookup(data, key);
      if (value !== null && value !== undefined) el.textContent = value;
    });

    document.querySelectorAll('[data-i18n-html]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-html');
      var value = lookup(data, key);
      if (value !== null && value !== undefined) el.innerHTML = value;
    });

    document.querySelectorAll('[data-i18n-attr]').forEach(function (el) {
      var spec = el.getAttribute('data-i18n-attr').split(':');
      var key = spec[0];
      var attr = spec[1] || 'placeholder';
      var value = lookup(data, key);
      if (value !== null && value !== undefined) el.setAttribute(attr, value);
    });

    var titleKey = 'seo.' + pageId + '.title';
    var descKey = 'seo.' + pageId + '.desc';
    var pageTitleEl = document.querySelector('[data-page-title]');
    if (pageTitleEl) titleKey = pageTitleEl.getAttribute('data-page-title');
    var tTitle = lookup(data, titleKey);
    var tDesc = lookup(data, descKey);
    if (tTitle) {
      document.title = tTitle;
      var ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle) ogTitle.setAttribute('content', tTitle);
    }
    if (tDesc) {
      var metaDesc = document.querySelector('meta[name="description"]');
      if (metaDesc) metaDesc.setAttribute('content', tDesc);
      var ogDesc = document.querySelector('meta[property="og:description"]');
      if (ogDesc) ogDesc.setAttribute('content', tDesc);
    }

    // Reformat dates according to the selected language
    document.querySelectorAll('.js-date').forEach(function (el) {
      var iso = el.getAttribute('data-iso');
      if (!iso) return;
      var d = new Date(iso + 'T00:00:00');
      if (isNaN(d)) return;
      var loc = current === 'hi' ? 'hi-IN' : current === 'mr' ? 'mr-IN' : 'en-GB';
      try {
        el.textContent = new Intl.DateTimeFormat(loc, {
          day: 'numeric', month: 'short', year: 'numeric',
          numberingSystem: 'latn'
        }).format(d);
      } catch (e) { /* keep existing text */ }
    });

    // Journal article body translation (English fallback if no version exists)
    var bodyEl = document.querySelector('[data-article-body]');
    if (bodyEl) {
      var tpl = document.querySelector('template[data-lang-body="' + current + '"]');
      if (tpl) bodyEl.innerHTML = tpl.innerHTML;
    }

    // Active state on language buttons
    document.querySelectorAll('[data-lang]').forEach(function (btn) {
      var on = btn.getAttribute('data-lang') === current;
      btn.classList.toggle('active', on);
      btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    });

    document.querySelectorAll('.js-switch-text').forEach(function (el) {
      el.textContent = SUPPORTED[current] || SUPPORTED[DEFAULT_LANG];
    });
  }

  function lookup(data, key) {
    var parts = key.split('.');
    var node = data;
    for (var i = 0; i < parts.length; i++) {
      if (!node) return null;
      node = node[parts[i]];
    }
    return node;
  }

  document.addEventListener('click', function (e) {
    var btn = e.target.closest ? e.target.closest('[data-lang]') : null;
    if (!btn) return;
    setLanguage(btn.getAttribute('data-lang'), true);
  });

  var saved = null;
  try { saved = localStorage.getItem(STORAGE_KEY); } catch (e) {}
  setLanguage(saved || DEFAULT_LANG, false);
})();
