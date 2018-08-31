import createPersistedState from 'vuex-persistedstate';
import Vue from 'vue';
import Vuex from 'vuex';

const initialStates = {
  granularity: 'day',
};

Vue.use(Vuex);

/**
 * A container that holds all application state. Changes to the store trigger
 * updates in store listeners (Vue components). The store cannot be mutated
 * directly. All mutations come through the interface provided by functions
 * under the mutations value.
 */
export default new Vuex.Store({
  state: {
    query: {
      startDate:   null,
      endDate:     null,
      granularity: initialStates.granularity,
    },
    datasets: null,
    host:     '',
    port:     4000,
    ssl:      false,
    selectedDatasetSlugs: [],
    compareMap: null
  },

  getters: {
    metaEndpoint: (state) => {
      const protocol = state.ssl ? 'https' : 'http';
      return `${protocol}://${state.host}:${state.port}/api/v2/data-sets`;
    },
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
     * Removes all the query arguments. Clears out the datasets.
     */
    clearQuery(state) {
      Vue.set(state, 'query', Object.assign(state.query, {
        startDate:   null,
        endDate:     null,
        granularity: initialStates.granularity,
      }));

      Vue.set(state, 'datasets', []);
    },

    /**
     * Stores a list of dataset slugs for the comparison page to use.
     */
    setSelectedDatasets(state, slugs) {
      Vue.set(state, 'selectedDatasetSlugs', slugs);
    },

    setCompareMap(state, map) {
      console.log('setCompareMap!');
      Vue.set(state, 'compareMap', map);
    },
  },

  plugins: [
    createPersistedState(),
  ],
});
