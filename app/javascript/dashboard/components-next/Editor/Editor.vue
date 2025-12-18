<script>
export default {
  name: 'NextEditor',
  props: {
    value: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    maxLength: {
      type: Number,
      default: undefined,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onInput(event) {
      const nextValue = event.target.value;
      this.$emit('input', nextValue);
      this.$emit('update:modelValue', nextValue);
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-1">
    <label v-if="label" class="text-sm font-medium text-n-slate-12">
      {{ label }}
    </label>
    <textarea
      class="w-full"
      :value="value"
      :placeholder="placeholder"
      :maxlength="maxLength"
      :disabled="disabled"
      rows="3"
      @input="onInput"
    />
  </div>
</template>
