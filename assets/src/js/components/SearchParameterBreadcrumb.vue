<template>
  <span class="badge bg-light text-muted font-weight-normal">
    <i :class="['far', icon]"></i>
    {{ text }}
  </span>
</template>

<script>
export default {
  props: {
    icon: { type: String, required: true },
    text: { type: String, required: true },
  },
};
</script>
