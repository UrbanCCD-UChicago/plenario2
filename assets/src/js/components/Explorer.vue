<template>
  <div>
    <div class="row no-gutters">
      <div class="row">
        <div class="col">
          <pre>@{{ host }}</pre>
        </div>
      </div>

      <div class="row">
        <div class="col-lg-4">
          <div class="row hairline-gutters">
            <space-search></space-search>
          </div>
          <div class="row hairline-gutters">
            <time-card></time-card>
          </div>
        </div>

        <div class="col-lg-8">
          <div class="card ml-lg-1">
            <!-- map -->
          </div>
        </div>
      </div>
    </div>

    <div v-if="hasSearchResults" class="row no-gutters">
      <search-results v-bind:value="searchResults"></search-results>
    </div>
  </div>
</template>


<script>
import SearchResults from './SearchResults.vue';
import SpaceSearch from './SpaceSearch.vue';
import TimeCard from './TimeCard.vue';

export default {
  name: 'Explorer',
  props: {
    host: {
      type: String,
      required: true
    }
  },

  data: function () {
    return {
      searchResults: {}
    }
  },

  computed: {

    /**
     * 
     */
    hasSearchResults: function () {
      return Object.keys(this.searchResults).length > 0;
    }
  },

  components: {
    SearchResults,
    SpaceSearch,
    TimeCard,
  }
}
</script>

