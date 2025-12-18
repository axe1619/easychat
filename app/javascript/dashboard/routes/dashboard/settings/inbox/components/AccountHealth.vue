<script>
import NextButton from 'next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    healthData: {
      type: Object,
      default: null,
    },
  },
  computed: {
    healthItems() {
      if (!this.healthData) return [];

      const {
        display_phone_number: displayPhoneNumber,
        verified_name: verifiedName,
        name_status: nameStatus,
        quality_rating: qualityRating,
        messaging_limit_tier: messagingLimitTier,
        account_mode: accountMode,
      } = this.healthData;

      return [
        {
          key: 'displayPhoneNumber',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_PHONE_NUMBER.LABEL'),
          value: displayPhoneNumber || 'N/A',
        },
        {
          key: 'verifiedName',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.VERIFIED_NAME.LABEL'),
          value: verifiedName || 'N/A',
        },
        {
          key: 'displayNameStatus',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.LABEL'),
          value: nameStatus || 'UNKNOWN',
        },
        {
          key: 'qualityRating',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.QUALITY_RATING.LABEL'),
          value: qualityRating || 'UNKNOWN',
        },
        {
          key: 'messagingLimitTier',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.MESSAGING_LIMIT_TIER.LABEL'),
          value: messagingLimitTier || 'UNKNOWN',
        },
        {
          key: 'accountMode',
          label: this.$t('INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.ACCOUNT_MODE.LABEL'),
          value: accountMode || 'UNKNOWN',
        },
      ];
    },
  },
  methods: {
    handleGoToSettings() {
      const { business_id: businessId } = this.healthData || {};
      const url = businessId
        ? `https://business.facebook.com/latest/whatsapp_manager/phone_numbers/?business_id=${businessId}&tab=phone-numbers`
        : 'https://business.facebook.com/';
      window.open(url, '_blank');
    },
  },
};
</script>

<template>
  <div class="gap-4 pt-8 mx-8">
    <div class="px-5 py-5 space-y-6 rounded-xl border shadow-sm border-n-weak bg-n-solid-2">
      <div class="flex flex-col gap-5 justify-between items-start w-full md:flex-row">
        <div>
          <span class="text-base font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ACCOUNT_HEALTH.TITLE') }}
          </span>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.ACCOUNT_HEALTH.DESCRIPTION') }}
          </p>
        </div>
        <NextButton solid blue class="flex-shrink-0" @click="handleGoToSettings">
          {{ $t('INBOX_MGMT.ACCOUNT_HEALTH.GO_TO_SETTINGS') }}
        </NextButton>
      </div>

      <div v-if="healthData" class="grid grid-cols-1 gap-4 xs:grid-cols-2">
        <div
          v-for="item in healthItems"
          :key="item.key"
          class="flex flex-col gap-2 p-4 rounded-lg border border-n-weak bg-n-solid-1"
        >
          <span class="text-sm font-medium text-n-slate-11">
            {{ item.label }}
          </span>
          <span class="text-sm font-medium text-n-slate-12">
            {{ item.value }}
          </span>
        </div>
      </div>

      <div v-else class="pt-8">
        <div class="flex justify-center items-center p-8 text-center text-n-slate-11">
          <p class="text-sm">{{ $t('INBOX_MGMT.ACCOUNT_HEALTH.NO_DATA') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
