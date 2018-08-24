<template>
  <div>
    <explorer-search-widget
      @search="search"
      @reset="reset" />
    <explorer-search-results
      v-if="datasets"
      :value="datasets" />
  </div>
</template>

<script>
import ExplorerSearchWidget from '../components/ExplorerSearchWidget.vue';
import ExplorerSearchResults from '../components/ExplorerSearchResults.vue';

export default {
  components: {
    ExplorerSearchWidget,
    ExplorerSearchResults,
  },
  computed: {
    host() { return this.$store.state.host; },
    port() { return this.$store.state.port; },
    ssl() { return this.$store.state.ssl; },
    datasets() { return this.$store.state.datasets; },
    endpoint() {
      const protocol = this.ssl ? 'https' : 'http';
      return `${protocol}://${this.host}:${this.port}/api/v2/data-sets`;
    },
  },
  methods: {
    async search() {
      // TODO: actually use form data
      const datasets = await fetch(this.endpoint)
        .then(response => response.json())
        .then(json => json.data);
      this.$store.commit('setDatasets', datasets);
    },
    reset() { this.$store.commit('clearQuery'); },
  },
};
</script>
