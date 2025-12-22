<script setup>
import { computed, ref, watch } from 'vue';
import PageHeader from '../../SettingsSubPageHeader.vue';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import { useI18n } from 'dashboard/composables/useI18n';

const { t } = useI18n();

const provider = ref('whatsapp_cloud');
const isManualSetup = ref(false);

const hasWhatsappAppId = computed(() => {
  return (
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});

const showEmbeddedSignup = computed(() => {
  return (
    provider.value === 'whatsapp_cloud' &&
    hasWhatsappAppId.value &&
    !isManualSetup.value
  );
});

const manualFallbackHtml = computed(() => {
  const linkText = t(
    'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_LINK_TEXT'
  );
  const linkHtml = `<a href="#" data-manual-link="true" class="underline text-woot-500 dark:text-woot-500">${linkText}</a>`;
  return t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_FALLBACK', {
    link: linkHtml,
  });
});

const onManualFallbackClick = event => {
  const target = event?.target;
  if (target?.dataset?.manualLink) {
    event.preventDefault();
    isManualSetup.value = true;
  }
};

watch(provider, newProvider => {
  if (newProvider !== 'whatsapp_cloud') {
    isManualSetup.value = false;
  }
});
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="whatsapp_cloud">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
          </option>
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
          </option>
        </select>
      </label>
    </div>

    <Twilio v-if="provider === 'twilio'" type="whatsapp" />
    <ThreeSixtyDialogWhatsapp v-else-if="provider === '360dialog'" />
    <div v-else>
      <div v-if="showEmbeddedSignup">
        <WhatsappEmbeddedSignup />
        <p
          class="pt-6 mt-6 text-sm text-slate-600 dark:text-slate-300 border-t border-slate-100 dark:border-slate-700"
          v-html="manualFallbackHtml"
          @click="onManualFallbackClick"
        ></p>
      </div>
      <CloudWhatsapp v-else />
    </div>
  </div>
</template>
