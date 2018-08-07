<template>
  <div class="col-12">
    <div class="form-group row">
      <label class="col-3" for="starting_on">Start</label>
      <datepicker class="col-9" v-model="startDate"></datepicker>
    </div>
    <div class="form-group row">
      <label class="col-3" for="ending_on">End</label>
      <datepicker class="col-9" v-model="endDate"></datepicker>
    </div>
    <div class="form-group row">
      <label for="granularity" class="control-label col-4">Granularity</label>
      <select id="granularity" name="granularity" class="form-control col-7" v-model="granularity" required>
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

  /**
   * The v-model directive looks for a property called 'value' to bind to. We
   * don't do anything with this property, it's just to play nice with the 
   * v-model directive.
   * 
   * https://vuejs.org/v2/guide/components.html#Using-v-model-on-Components
   */
  props: {
    value: {
      required: true,
      type: Object
    }
  },

  data: function () {
    return {
      startDate: '',
      endDate: '',
      granularity: ''
    }
  },

  components: {
    Datepicker
  },
};
</script>
 