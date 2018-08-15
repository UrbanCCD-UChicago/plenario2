<template>
  <div>
    <comparer />
    <div class="row no-gutters">
      <div class="row">
        <div class="col">
          <pre>@{{ host }}</pre>
        </div>
      </div>

      <div class="row">
        <div class="col-lg-4">
          <div class="row hairline-gutters">
            <space-search :v-model="spaceParams"></space-search>
          </div>
          <div class="row hairline-gutters">
            <time-card :v-model="timeParams"></time-card>
          </div>
          <div class="row hairline-gutters">
            <action-card
              v-bind:url="endpoint"
              v-bind:query="query"
              v-on:search="updateSearchResults">
            </action-card>
          </div>
        </div>

        <div class="col-lg-8 card">
        </div>
      </div>
    </div>

    <br>
    <br>

    <div v-if="hasSearchResults" class="row no-gutters">
      <search-results v-bind:value="searchResults"></search-results>
    </div>
  </div>
</template>


<script>
import ActionCard from './ActionCard.vue';
import LMap from './LMap.vue';
import SearchResults from './SearchResults.vue';
import SpaceSearch from './SpaceSearch.vue';
import TimeCard from './TimeCard.vue';
import Comparer from './Comparer.vue';

export default {
  name: 'Explorer',
  props: {

    /**
     * 
     */
    host: {
      required: true,
      type: String
    },

    /**
     * 
     */
    port: {
      required: true,
      type: Number
    },

    /**
     * 
     */
    ssl: {
      required: true,
      type: Boolean
    },

    /**
     * 
     */
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

    /**
     * 
     */
    hasSearchResults: function () {
      return Object.keys(this.searchResults).length > 0;
    },

    /**
     * 
     */
    endpoint: function () {
      return this.ssl ?
        'https://' + this.host + ':' + this.port + '/api/v' + this.api + '/data-sets/' :
        'http://' + this.host + ':' + this.port + '/api/v' + this.api + '/data-sets/';
    },

    /**
     * 
     */
    query: function () {
      return Object.assign(this.spaceParams, this.timeParams);
    }
  },

  components: {
    ActionCard,
    LMap,
    SearchResults,
    SpaceSearch,
    TimeCard,
    Comparer
  },

  methods: {

    /**
     * 
     */
    updateSearchResults: function (event) {
      this.searchResults = event;
    }
  },

 
}
</script>
