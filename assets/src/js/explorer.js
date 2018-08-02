import Vue from 'vue';

import Explorer from './components/Explorer.vue';


new Vue({
  components: { Explorer }
}).$mount('#app');

new Pikaday({
  field: document.getElementById('starting_on'),
  format: 'YYYY-MM-DD'
});

new Pikaday({
  field: document.getElementById('ending_on'),
  format: 'YYYY-MM-DD'
});