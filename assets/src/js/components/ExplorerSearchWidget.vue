<template>
  <div>
    <div class="card search-widget">
      <div class="row no-gutters flex-lg-column">
        <div class="space-text-section col-lg-4">
          <div class="card-body">
            <font-awesome-layers class="fa-2x float-left mr-2">
              <font-awesome-icon icon="circle" class="text-info" transform="up-0.5"></font-awesome-icon>
              <font-awesome-icon icon="pencil-alt" class="text-white" transform="up-0.5 shrink-7"></font-awesome-icon>
            </font-awesome-layers>
            <p class="lead card-text">Draw a search area.</p>
            <p class="small text-muted card-text">You can use any or all of the available tools;
            overlapping areas will be unioned.</p>
          </div>
        </div>
        <div class="space-map-section col-lg-8 order-lg-last">
          <l-map drawTools></l-map>
        </div>
        <div class="time-section col-lg-4">
          <div class="card-body">
            <font-awesome-layers class="fa-2x float-left mr-2">
              <font-awesome-icon icon="circle" class="text-info" transform="up-0.5"></font-awesome-icon>
              <font-awesome-icon :icon="['far', 'calendar-alt']" class="text-white" transform="up-0.5 shrink-7"></font-awesome-icon>
            </font-awesome-layers>
            <p class="lead card-text">Select a date range.</p>
            <p class="small text-muted card-text">Granularity controls how Plenario groups data in
            charts. You can always download all the individual data points within the range you
            specify.</p>
            <time-range-form></time-range-form>
          </div>
        </div>
        <div class="action-section col-lg-4 flex-grow-1 d-flex flex-column justify-content-end">
          <div class="card-body">
            <div class="row hairline-gutters">
              <div class="col-auto">
                <button class="btn btn-block btn-danger" @click="reset">
                  <font-awesome-icon icon="undo"></font-awesome-icon>
                  <span class="d-lg-none">Reset</span>
                </button>
              </div>
              <div class="col">
                <button class="btn btn-block btn-info" @click="search">
                  <font-awesome-icon icon="search"></font-awesome-icon>
                  Search
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="card my-3 px-2 py-3" v-if="hasSearchResults">
      <div class="row no-gutters">
        <search-results v-bind:value="this.datasets"></search-results>
      </div>
    </div>
  </div>
</template>


<style lang="scss" scoped>
@import "~bootstrap/scss/functions";
@import "~bootstrap/scss/variables";
@import "~bootstrap/scss/mixins/breakpoints";
@import "../../css/convenience-variables";

$front-matter-height:
  $navbar-spacing +
  ($h1-font-size * $headings-line-height) + $headings-margin-bottom;
$widget-landscape-max-height:
  calc(100vh - #{$front-matter-height + $spacer});

.search-widget {
  @include media-breakpoint-up(lg) {
    max-height: $widget-landscape-max-height;
  }
}

.space-text-section,
.time-section {
  @include media-breakpoint-up(lg) {
    flex-basis: auto;
  }
}

.space-map-section {
  flex-basis: 100%;

  @include media-breakpoint-up(lg) {
    height: $widget-landscape-max-height;
  }
}

.action-section {
  .card-body {
    flex: 0;
  }
}

.map {
  min-height: 25rem;

  @include media-breakpoint-up(lg) {
    // The magic numbers below serve to properly align the leaflet map within
    // the container. It wants to collapse to 0px tall without the absolute
    // positioning, but with it the map overlaps the borders of the card and
    // doesn't inherit the parent's rounded corners. This adjusts it to hide
    // those sins.
    $map-border-radius: $card-border-radius - 0.05rem;
    height: calc(100% - 2px);
    left: 1px;
    border-radius: 0 $map-border-radius $map-border-radius 0;
  }
}
</style>


<script>
import LMap from './LMap.vue';
import TimeRangeForm from './TimeRangeForm.vue';
import SearchResults from './SearchResults.vue';

export default {
  components: {
    LMap,
    TimeRangeForm,
  },
  computed: {
    ssl: function () {
      return this.$store.state.ssl;
    },

    host: function () {
      return this.$store.state.host;
    },

    port: function () {
      return this.$store.state.port;
    },
    
    datasets: function () {
      return this.$store.state.datasets;
    },

    endpoint: function () {
      var http_or_https = this.ssl ? 'https' : 'http';
      return `${http_or_https}://${this.host}:${this.port}/api/v2/data-sets`;
    },

    hasSearchResults: function () {
      return this.datasets.length > 0;
    },
  },
  methods: {
    /**
     * The handler for click events on our search button.
     * 
     * - Needs error handling!
     */
    search: async function (_) {
      var json = await fetch(this.endpoint).then(function(response) {
        return response.json();
      });

      this.$store.commit('setDatasets', json.data);
    },

    /**
     * The handler for click events on our reset button. Listeners for this 
     * event should clear their state.
     */
    reset: function (_) {
      this.$store.commit('clearQuery');
    }
  },
  components: {
    LMap,
    SearchResults,
    TimeRangeForm,
  }
}
</script>
