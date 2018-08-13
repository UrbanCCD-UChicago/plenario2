import Vue from 'vue';
import Vuex from 'vuex';

import Explorer from './components/Explorer.vue';

Vue.use(Vuex);

/**
 * A container that holds all application state. Changes to the store trigger
 * updates in store listeners (Vue components). The store cannot be mutated
 * directly. All mutations come through the interface provided by functions
 * under the mutations value.
 */
const store = new Vuex.Store({
  state: {
    query: {},
    datasets: {}
  },

  mutations: {

    /**
     * Assign parameter values to the query state.
     * 
     * @param {Object} state 
     * @param {Object} params 
     */
    assignQuery (state, params) {
      Vue.set(state, 'query', Object.assign(state.query, params));
    }
  }
});

new Vue({
  components: { Explorer },

  /**
   * Inject the `store` into all child components. Any children of this root
   * component will have access to a `$store` property containing the 
   * application state.
   */
  store: store
}).$mount('#app');
