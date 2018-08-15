/* global $:false */

import * as L from 'leaflet';
import 'leaflet-draw';
import Vue from 'vue';

/* CSS imports (needed to force Webpack to bundle them) */
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';

// So current Leaflet implementation doesn't break
window.L = L;

// Only mount Vue once page has loaded
$(() => {
  new Vue({}).$mount('#app');
});
