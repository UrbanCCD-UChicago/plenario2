<template>
  <router-view />
</template>

<script>
export default {
  props: {
    host: { type: String, required: true },
    port: { type: Number, required: true },
    ssl:  { type: Boolean, required: true },
  },
  mounted() {
    this.$store.state.host = this.host;
    this.$store.state.port = this.port;
    this.$store.state.ssl = this.ssl;
  },
};
</script>
