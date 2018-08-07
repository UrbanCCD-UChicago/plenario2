<template>
  <div>
    {{ value }}
  </div>
</template>

<script>
export default {
  name: 'SearchResults',
  props: {
    value: {
      required: true,
      type: Object
    }
  }
}
</script>

