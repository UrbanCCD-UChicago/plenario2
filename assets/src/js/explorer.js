import Vue from 'vue';

import SpaceSearch from './components/SpaceSearch.vue';
import TimeCard from './components/TimeCard.vue';
import ActionCard from './components/ActionCard.vue'



new Vue({
  components: {
    SpaceSearch,
    TimeCard,
    ActionCard
  }
}).$mount('#app');

new Pikaday({
  field: document.getElementById('starting_on'),
  format: 'YYYY-MM-DD'
});

new Pikaday({
  field: document.getElementById('ending_on'),
  format: 'YYYY-MM-DD'
});