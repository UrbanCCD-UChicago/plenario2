import Vue from 'vue';
import Router from 'vue-router';
import Compare from './views/ExplorerCompare.vue';
import Search from './views/ExplorerSearch.vue';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path:      '/',
      name:      'search',
      component: Search,
    },
    {
      path:      '/compare',
      name:      'compare',
      component: Compare,
    },
  ],
});
