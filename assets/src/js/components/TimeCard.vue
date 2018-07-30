<template>
  <div class="col-lg-4 float-lg-left pr-lg-1">
    <div class="card time-card">
      <time-card-header></time-card-header>
      <time-card-body></time-card-body>
    </div>
  </div>
</template>

<script>
import TimeCardHeader from './TimeCardHeader.vue';
import TimeCardBody from './TimeCardBody.vue';

export default {
  name: 'TimeCard',
  components: {
    TimeCardBody,
    TimeCardHeader
  }
}
</script>
