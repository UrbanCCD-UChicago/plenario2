<template>
  <div class="time-range-form">
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="starting_on">Start</label>
      <datepicker required bootstrap-styling
        @input="setStartDate" 
        class="col" 
        input-class="bg-white"
        :value="startDate">
      </datepicker>
    </div>
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="ending_on">End</label>
      <datepicker required bootstrap-styling
        @input="setEndDate" 
        class="col" 
        input-class="bg-white" 
        :value="endDate">
      </datepicker>
    </div>
    <div class="form-group form-row">
      <label for="granularity" class="col-sm-2 col-sm-4 col-form-label">Granularity</label>
      <div class="col">
        <select required 
          @click="setGranularity" 
          id="granularity" 
          name="granularity" 
          class="custom-select"
          :value="granularity">
          <option value="day">Day</option>
          <option value="week">Week</option>
          <option value="month">Month</option>
          <option value="year">Year</option>
        </select>
      </div>
    </div>
  </div>
</template>

<style lang="scss">
@import "~bootstrap/scss/functions";
@import "~bootstrap/scss/variables";

.vdp-datepicker__calendar { z-index: $zindex-popover; }
</style>


<script>
/**
 * A component for choosing a date. We use this to provide time range query
 * parameters to the backend api.
 */
import Datepicker from 'vuejs-datepicker';

export default {
  name: 'TimeRangeForm',

  computed: {
    startDate: function() {
      return this.$store.state.query.startDate;
    },

    endDate: function() {
      return this.$store.state.query.endDate;
    },

    granularity: function() {
      return this.$store.state.query.granularity;
    },
  },

  methods: {
    setStartDate (startDate) {
      this.$store.commit('setQuery', { startDate });
    },

    setEndDate (endDate) {
      this.$store.commit('setQuery', { endDate });
    },

    setGranularity (event) {
      this.$store.commit('setQuery', { granularity: event.target.value });
    },
  },

  components: {
    Datepicker
  },
};
</script>
 