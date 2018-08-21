<template>
  <router-view />
</template>

<script>
export default {
  props: {
    host: {
      required: true,
      type: String
    },

    port: {
      required: true,
      type: Number
    },

    ssl: {
      required: true,
      type: Boolean
    },
  },

  mounted: function () {
    this.$store.state.host = this.host;
    this.$store.state.port = this.port;
    this.$store.state.ssl = this.ssl;
  }
}
</script>
