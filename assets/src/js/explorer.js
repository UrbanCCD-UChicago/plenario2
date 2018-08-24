/* global $:false */
import { FontAwesomeIcon, FontAwesomeLayers } from '@fortawesome/vue-fontawesome';
import * as L from 'leaflet';
import 'leaflet-draw';
import Vue from 'vue';
import App from './ExplorerApp.vue';
import router from './explorer-router';
import store from './explorer-store';

// Register Font Awesome components globally so we don't have to import and declare them in every
// component we use an icon in
Vue.component('FontAwesomeIcon', FontAwesomeIcon);
Vue.component('FontAwesomeLayers', FontAwesomeLayers);

// So current Leaflet implementation doesn't break
window.L = L;

// Only mount Vue once page has loaded
$(() => {
  new Vue({
    router,
    store,
    render: h => h(App, {
      // We populate the root instance's props from HTML data attributes injected on our #app
      // element via the Phoenix template
      props: {
        host: $('#app').attr('data-api-host'),
        port: Number($('#app').attr('data-api-port')),
        ssl:  $('#app').attr('data-api-ssl') === 'true',
      },
    }),
  }).$mount('#app');
});
