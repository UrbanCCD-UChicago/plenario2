<template>
  <div class="explorer">
    <explorer-search-widget 
      :apiUrl="endpoint"
      @reset="handleReset">
    </explorer-search-widget>

    <div v-if="hasSearchResults" class="row no-gutters">
      <search-results v-bind:value="this.datasets"></search-results>
    </div>
  </div>
</template>


<script>
import ExplorerSearchWidget from "./ExplorerSearchWidget.vue";
import SearchResults from './SearchResults.vue';

export default {
  name: 'Explorer',
  props: {
    host: {
      required: true,
      type: String
    },
    port: {
      required: true,
      type: Number
    },
    ssl: {
      required: true,
      type: Boolean
    },
    api: {
      required: true,
      type: Number
    }
  },

  data: function () {
    return {
      timeParams: {},
      spaceParams: {}
    }
  },

  computed: {
    datasets: function () {
      return this.$store.state.datasets;
    },
    hasSearchResults: function() {
      return this.datasets.length > 0;
    },
    endpoint: function() {
      return this.ssl ?
        `https://${this.host}:${this.port}/api/v${this.api}/data-sets/` :
        `http://${this.host}:${this.port}/api/v${this.api}/data-sets/`;
    },
    query: function () {
      return Object.assign(this.spaceParams, this.timeParams);
    }
  },

  methods: {
    handleReset: function () {
      this.$store.commit('clearQuery');
    }
  },
  
  components: {
    SearchResults,
    ExplorerSearchWidget,
  },
}
</script>
