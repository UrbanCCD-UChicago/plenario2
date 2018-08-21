<template>
  <div class="explorer">
    <explorer-search-widget
      :apiUrl="endpoint"
      @search="doSearch">
    </explorer-search-widget>

    <div v-if="hasSearchResults" class="row no-gutters">
      <search-results v-bind:value="searchResults"></search-results>
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
      searchResults: {},
      timeParams: {},
      spaceParams: {}
    }
  },

  computed: {
    hasSearchResults: function() {
      return Object.keys(this.searchResults).length > 0;
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
  components: {
    SearchResults,
    ExplorerSearchWidget,
  },
  methods: {
    doSearch: function (event) {
      this.searchResults = event;
    }
  },

}
</script>
