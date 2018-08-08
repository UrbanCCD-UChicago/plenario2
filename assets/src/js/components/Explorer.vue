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
          <div class="row hairline-gutters">
            <action-card
              v-bind:url="endpoint"
              v-bind:query="query"
              v-on:search="updateSearchResults">
            </action-card>
          </div>
        </div>

        <div class="col-lg-8 card">
          <l-map ref="map" :zoom=13 :center="[47.413220, -1.219482]">
          </l-map>
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
import { LMap } from 'vue2-leaflet';

import ActionCard from './ActionCard.vue';
import SearchResults from './SearchResults.vue';
import SpaceSearch from './SpaceSearch.vue';
import TimeCard from './TimeCard.vue';

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
      query: {}
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
    }
  },

  components: {
    ActionCard,
    LMap,
    SearchResults,
    SpaceSearch,
    TimeCard,
  },

  methods: {

    /**
     * 
     */
    updateSearchResults: function (event) {
      this.searchResults = event;
    }
  }
}
</script>

