<script>
export default {
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <p class="text-sm text-n-slate-11">
      {{ $t('INBOX_MGMT.CSAT.TITLE') }}
    </p>
  </div>
</template>
