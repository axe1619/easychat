<script>
export default {
  name: 'NextAvatar',
  props: {
    src: {
      type: String,
      default: '',
    },
    size: {
      type: Number,
      default: 48,
    },
    iconName: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    allowUpload: {
      type: Boolean,
      default: false,
    },
    roundedFull: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    initials() {
      const parts = this.name.trim().split(/[ -]/).filter(Boolean);
      const initials = parts.map(part => part.charAt(0)).join('');
      return initials.substring(0, 2).toUpperCase();
    },
    sizeStyle() {
      return {
        width: `${this.size}px`,
        height: `${this.size}px`,
      };
    },
    radiusClass() {
      return this.roundedFull ? 'rounded-full' : 'rounded-md';
    },
  },
  methods: {
    handleFileChange(event) {
      const [file] = event.target.files;
      if (!file) return;
      this.$emit('upload', {
        file,
        url: URL.createObjectURL(file),
      });
    },
    handleDelete() {
      this.$emit('delete');
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      class="flex items-center justify-center bg-slate-100 text-slate-700 overflow-hidden"
      :class="radiusClass"
      :style="sizeStyle"
    >
      <img v-if="src" :src="src" :alt="name" :style="sizeStyle" />
      <fluent-icon v-else-if="iconName" :icon="iconName" />
      <span v-else class="text-sm font-medium">{{ initials }}</span>
    </div>
    <div v-if="allowUpload" class="flex items-center gap-2">
      <label class="button nice">
        <input
          type="file"
          class="hidden"
          accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
          @change="handleFileChange"
        />
        Upload
      </label>
      <button v-if="src" type="button" class="button nice" @click="handleDelete">
        {{ $t('INBOX_MGMT.DELETE.AVATAR_DELETE_BUTTON_TEXT') }}
      </button>
    </div>
  </div>
</template>
