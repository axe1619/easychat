<script>
export default {
  props: {
    content: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div class="mx-8 mt-5 p-3 rounded border border-yellow-200 bg-yellow-50 text-yellow-900">
    {{ content }}
  </div>
</template>
