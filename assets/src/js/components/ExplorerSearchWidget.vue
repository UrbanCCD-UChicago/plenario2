<template>
  <div class="card search-widget">
    <div class="row no-gutters flex-lg-column">
      <div class="space-text-section col-lg-4">
        <div class="card-body">
          <FontAwesomeLayers class="fa-2x float-left mr-2">
            <FontAwesomeIcon icon="circle"
                             class="text-info"
                             transform="up-0.5" />
            <FontAwesomeIcon icon="pencil-alt"
                             class="text-white"
                             transform="up-0.5 shrink-7" />
          </FontAwesomeLayers>
          <p class="lead card-text">Draw a search area.</p>
          <p class="small text-muted card-text">You can use any or all of the available tools;
          overlapping areas will be unioned.</p>
        </div>
      </div>
      <div class="space-map-section col-lg-8 order-lg-last">
        <LMap :draw-tools="true" />
      </div>
      <div class="time-section col-lg-4">
        <div class="card-body">
          <FontAwesomeLayers class="fa-2x float-left mr-2">
            <FontAwesomeIcon icon="circle"
                             class="text-info"
                             transform="up-0.5" />
            <FontAwesomeIcon :icon="['far', 'calendar-alt']"
                             class="text-white"
                             transform="up-0.5 shrink-7" />
          </FontAwesomeLayers>
          <p class="lead card-text">Select a date range.</p>
          <p class="small text-muted card-text">Granularity controls how Plenario groups data in
          charts. You can always download all the individual data points within the range you
          specify.</p>
          <TimeRangeForm />
        </div>
      </div>
      <div class="action-section col-lg-4 flex-grow-1 d-flex flex-column justify-content-end">
        <div class="card-body">
          <div class="row hairline-gutters">
            <div class="col-auto">
              <button class="btn btn-block btn-danger"
                      @click="$emit('reset')">
                <FontAwesomeIcon icon="undo" />
                <span class="d-lg-none">Reset</span>
              </button>
            </div>
            <div class="col">
              <button class="btn btn-block btn-info"
                      @click="$emit('search')">
                <FontAwesomeIcon icon="search" />
                Search
              </button>
            </div>
          </div>
        </div>
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

export default {
  components: {
    LMap,
    TimeRangeForm,
  },
};
</script>
