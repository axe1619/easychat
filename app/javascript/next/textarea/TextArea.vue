<script>
export default {
  name: 'NextTextArea',
  props: {
    value: {
      type: String,
      default: '',
    },
    modelValue: {
      type: String,
      default: undefined,
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    autoHeight: {
      type: Boolean,
      default: false,
    },
    minHeight: {
      type: String,
      default: '4rem',
    },
    maxHeight: {
      type: String,
      default: '12rem',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    currentValue() {
      return this.modelValue !== undefined ? this.modelValue : this.value;
    },
    textAreaStyle() {
      if (!this.autoHeight) return {};
      return {
        minHeight: this.minHeight,
        maxHeight: this.maxHeight,
      };
    },
  },
  watch: {
    currentValue() {
      this.$nextTick(this.adjustHeight);
    },
  },
  mounted() {
    this.adjustHeight();
  },
  methods: {
    onInput(event) {
      const nextValue = event.target.value;
      this.$emit('input', nextValue);
      this.$emit('update:modelValue', nextValue);
      this.adjustHeight();
    },
    adjustHeight() {
      if (!this.autoHeight || !this.$refs.textarea) return;
      const el = this.$refs.textarea;
      el.style.height = 'auto';
      el.style.height = `${el.scrollHeight}px`;
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
      ref="textarea"
      class="w-full"
      :value="currentValue"
      :placeholder="placeholder"
      :style="textAreaStyle"
      :disabled="disabled"
      rows="1"
      @input="onInput"
    />
  </div>
</template>
