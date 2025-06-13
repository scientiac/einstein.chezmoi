// ==UserScript==
// @name         YouTube Auto Pause Minimal
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Pause YouTube videos on load and navigation until manually played
// @author       You
// @match        *://*.youtube.com/*
// @grant        none
// ==/UserScript==

(function() {
  'use strict';


  // Hide the player visually
  const style = document.createElement('style');
  style.textContent = '.ytd-ad-slot-renderer, .ytd-watch-next-secondary-results-renderer, #player { display: none !important; }';
  (document.head || document.documentElement).appendChild(style);

  function pauseVideoIfPlaying() {
    const video = document.querySelector('video');
    if (video && !video.paused && !video.ended) {
      video.pause();
      console.log('[AutoPause] Video was auto-paused.');
    }
  }

  function observeVideoPresence() {
    const observer = new MutationObserver(() => {
      pauseVideoIfPlaying();
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  function setupPauseOnLoadAndNavigation() {
    pauseVideoIfPlaying();

    window.addEventListener('yt-navigate-finish', () => {
      pauseVideoIfPlaying();
    });
  }

  setupPauseOnLoadAndNavigation();
  observeVideoPresence();
})();
