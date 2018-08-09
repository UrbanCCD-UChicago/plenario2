<template>
  <div class="col-12">
    <div class="form-group row">
      <label class="col-3" for="starting_on">Start</label>
      <datepicker @input="updateStore" class="col-9" v-model="startDate"></datepicker>
    </div>
    <div class="form-group row">
      <label class="col-3" for="ending_on">End</label>
      <datepicker @input="updateStore" class="col-9" v-model="endDate"></datepicker>
    </div>
    <div class="form-group row">
      <label for="granularity" class="control-label col-4">Granularity</label>
      <select @click="updateStore" id="granularity" name="granularity" class="form-control col-7" v-model="granularity" required>
        <option value="day">Day</option>
        <option value="week">Week</option>
        <option value="month">Month</option>
        <option value="year">Year</option>
      </select>
    </div>
  </div>
</template>

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
 