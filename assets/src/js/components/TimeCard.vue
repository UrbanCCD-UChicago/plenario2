<template>
  <div class="card time-card">
    <time-card-header></time-card-header>
    <time-card-body></time-card-body>
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
