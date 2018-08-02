<template>
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
          <action-card></action-card>
        </div>
      </div>

      <div class="col-lg-8">
        <div class="card ml-lg-1">
          <!-- map -->
        </div>
      </div>
    </div>
  </div>
</template>


<script>
import SpaceSearch from './SpaceSearch.vue';
import TimeCard from './TimeCard.vue';
import ActionCard from './ActionCard.vue'

export default {
  name: 'Explorer',
  props: {
    host: {
      type: String,
      required: true
    }
  },
  components: {
    SpaceSearch,
    TimeCard,
    ActionCard
  }
}
</script>

