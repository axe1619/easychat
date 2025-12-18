<script>
export default {
  name: 'NextIcon',
  inheritAttrs: false,
  props: {
    icon: {
      type: String,
      required: true,
    },
    size: {
      type: [String, Number],
      default: undefined,
    },
  },
};
</script>

<template>
  <fluent-icon :icon="icon" :size="size" v-bind="$attrs" />
</template>
