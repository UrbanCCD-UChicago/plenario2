<template>
  <div class="explorer">
    <explorer-search-widget 
      :apiUrl="endpoint"
      @reset="handleReset">
    </explorer-search-widget>

    <div class="card my-3 px-2 py-3" v-if="hasSearchResults">
      <div class="row no-gutters">
        <search-results v-bind:value="this.datasets"></search-results>
      </div>
    </div>
  </div>
</template>

<script>
import ExplorerSearchWidget from "./ExplorerSearchWidget.vue";
import SearchResults from './SearchResults.vue';

export default {
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
  },

  mounted: function () {
    this.$store.state.host = this.host;
    this.$store.state.port = this.port;
    this.$store.state.ssl = this.ssl;
  }
}
</script>
