<template>
  <div class="time-range-form">
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="starting_on">Start</label>
      <datepicker required @input="updateStore" class="col" input-class="bg-white" bootstrap-styling v-model="startDate"></datepicker>
    </div>
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="ending_on">End</label>
      <datepicker required @input="updateStore" class="col" input-class="bg-white" bootstrap-styling v-model="endDate"></datepicker>
    </div>
    <div class="form-group form-row">
      <label for="granularity" class="col-sm-2 col-sm-4 col-form-label">Granularity</label>
      <div class="col">
        <select @click="updateStore" id="granularity" name="granularity" class="custom-select" v-model="granularity" required>
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

  data: function () {
    return {
      startDate: '',
      endDate: '',
      granularity: ''
    }
  },

  methods: {
    updateStore () {
      this.$store.commit('assignQuery', {
        startDate: this.startDate,
        endDate: this.endDate,
        granularity: this.granularity
      });
    }
  },

  components: {
    Datepicker
  },
};
</script>
 