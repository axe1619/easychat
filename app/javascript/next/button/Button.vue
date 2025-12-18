<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'NextButton',
  components: {
    Spinner,
  },
  props: {
    type: {
      type: String,
      default: 'button',
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    label: {
      type: String,
      default: '',
    },
    solid: {
      type: Boolean,
      default: false,
    },
    outline: {
      type: Boolean,
      default: false,
    },
    ghost: {
      type: Boolean,
      default: false,
    },
    faded: {
      type: Boolean,
      default: false,
    },
    blue: {
      type: Boolean,
      default: false,
    },
    teal: {
      type: Boolean,
      default: false,
    },
    slate: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    buttonClasses() {
      return [
        this.solid && 'solid',
        this.outline && 'outline',
        this.ghost && 'ghost',
        this.faded && 'faded',
        this.blue && 'blue',
        this.teal && 'teal',
        this.slate && 'slate',
      ].filter(Boolean);
    },
  },
  methods: {
    onClick(event) {
      this.$emit('click', event);
    },
  },
};
</script>

<template>
  <button
    :type="type"
    class="button nice"
    :class="buttonClasses"
    :disabled="disabled || isLoading"
    @click="onClick"
  >
    <Spinner v-if="isLoading" class="mr-1" />
    <slot>{{ label }}</slot>
  </button>
</template>
