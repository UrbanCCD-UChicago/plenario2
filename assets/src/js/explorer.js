/* global $:false */

import * as L from 'leaflet';
import 'leaflet-draw';
import Vue from 'vue';
import Vuex from 'vuex';
import VueRouter from 'vue-router';

/* CSS imports (needed to force Webpack to bundle them) */
import 'chartist/dist/chartist.min.css';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import { FontAwesomeIcon, FontAwesomeLayers } from '@fortawesome/vue-fontawesome';
import Explorer from './components/Explorer.vue';
import ExplorerSearchWidget from './components/ExplorerSearchWidget.vue';
import Compare from './components/compare/Compare.vue';

Vue.component('font-awesome-icon', FontAwesomeIcon);
Vue.component('font-awesome-layers', FontAwesomeLayers);
Vue.use(Vuex);
Vue.use(VueRouter);


const DEFAULT_GRANULARITY = 'day';

/**
 * A container that holds all application state. Changes to the store trigger
 * updates in store listeners (Vue components). The store cannot be mutated
 * directly. All mutations come through the interface provided by functions
 * under the mutations value.
 */
const store = new Vuex.Store({
  state: {
    query:    {
      startDate: null,
      endDate: null,
      granularity: DEFAULT_GRANULARITY,
    },
    datasets: [],
    selectedDatasets: [],
    host: '',
    port: 4000,
    ssl: false
  },

  mutations: {

    /**
     * Assign parameter values to the query state. Use this to construct queries
     * made against the backend.
     *
     * @param {Object} state
     * @param {Object} params
     */
    setQuery(state, params) {
      Vue.set(state, 'query', Object.assign(state.query, params));
    },

    /**
     * Setter for `datasets` state. Populate this object with the results from
     * queries to the backend.
     */
    setDatasets(state, params) {
      Vue.set(state, 'datasets', params);
    },

    /**
     * Setter for `datasets` state. Populate this object with the datasets
     * you wish to render on the comparison page.
     */
    setSelectedDatasets(state, params) {
      Vue.set(state, 'selectedDatasets', params);
    },

    /**
     * Removes all the query arguments. Clears out the datasets.
     */
    clearQuery(state) {
      Vue.set(state, 'query', Object.assign(state.query, {
        startDate: null,
        endDate: null,
        granularity: DEFAULT_GRANULARITY,
      }));

      Vue.set(state, 'datasets', []);
    }
  },
});

/**
 * Each route should map to a component. The "component" can
 * either be an actual component constructor created via
 * `Vue.extend()`, or just a component options object.
 * 
 * These components are rendered to the `<router-view>` outlet.
 */
const routes = [
  {
    path: '/', component: ExplorerSearchWidget,
  },
  {
    path: '/compare', component: Compare,
  }
];

const router = new VueRouter({ routes });

// So current Leaflet implementation doesn't break
window.L = L;

// Only mount Vue once page has loaded
$(() => {
  new Vue({

    /**
     * Inject the `store` into all child components. Any children of this root
     * component will have access to a `$store` property containing the
     * application state.
     */
    store,

    /**
     * Inject the `router` into all child components. Children of this root
     * component can render other components to the outlet using the `to=`
     * HTML directive.
     * 
     * Children of this root also all have access to a `$route` property.
     */
    router,

    components: {
      Explorer
    }
  }).$mount('#app');
});
