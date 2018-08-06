<template>
  <div class="card-body">
    <div class="row">
      <div class="col-12 col-md-4 col-lg-12">
        <p class="card-text">
            Select a date range, then choose how to group event data.
        </p>
        <p class="text-muted small">
            "Aggregate by" tells Plenar.io whether you care about the number of datapoints per <em>day</em>, per
            <em>week</em>, or aggregated over another unit of time.
        </p>
      </div>
      <time-range-form></time-range-form>
    </div>
  </div>
</template>

<script>
import TimeRangeForm from './TimeRangeForm.vue';

export default {
  name: 'TimeCardBody',
  components: {
    TimeRangeForm
  }
}
</script>
