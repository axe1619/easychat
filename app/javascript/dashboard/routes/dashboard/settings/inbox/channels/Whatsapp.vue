<script>
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';

export default {
  components: {
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    WhatsappEmbeddedSignup,
    ChannelSelector,
  },
  data() {
    return {
      PROVIDER_TYPES: {
        WHATSAPP: 'whatsapp',
        TWILIO: 'twilio',
        WHATSAPP_CLOUD: 'whatsapp_cloud',
        WHATSAPP_EMBEDDED: 'whatsapp_embedded',
        WHATSAPP_MANUAL: 'whatsapp_manual',
        THREE_SIXTY_DIALOG: '360dialog',
      },
    };
  },
  computed: {
    hasWhatsappAppId() {
      return (
        window.chatwootConfig?.whatsappAppId &&
        window.chatwootConfig.whatsappAppId !== 'none'
      );
    },
    selectedProvider() {
      return this.$route.query.provider;
    },
    showProviderSelection() {
      return !this.selectedProvider;
    },
    showConfiguration() {
      return Boolean(this.selectedProvider);
    },
    availableProviders() {
      return [
        {
          key: this.PROVIDER_TYPES.WHATSAPP,
          title: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
          description: this.$t(
            'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'
          ),
          icon: 'i-woot-whatsapp',
        },
        {
          key: this.PROVIDER_TYPES.TWILIO,
          title: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
          description: this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
          icon: 'i-woot-twilio',
        },
      ];
    },
    manualFallbackParts() {
      const full = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_FALLBACK'
      );
      const token = '{link}';
      if (full.includes(token)) {
        const [prefix, suffix] = full.split(token);
        return { prefix, suffix };
      }
      return { prefix: full, suffix: '' };
    },
  },
  methods: {
    selectProvider(providerValue) {
      this.$router.push({
        name: this.$route.name,
        params: this.$route.params,
        query: { provider: providerValue },
      });
    },
    shouldShowCloudWhatsapp(provider) {
      return (
        provider === this.PROVIDER_TYPES.WHATSAPP_MANUAL ||
        (provider === this.PROVIDER_TYPES.WHATSAPP && !this.hasWhatsappAppId)
      );
    },
    handleManualLinkClick() {
      this.selectProvider(this.PROVIDER_TYPES.WHATSAPP_MANUAL);
    },
  },
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <div class="flex gap-6 justify-start">
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="provider.description"
          :icon="provider.icon"
          @click="selectProvider(provider.key)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <div class="px-6 py-5 rounded-2xl border border-n-weak">
        <div
          v-if="
            hasWhatsappAppId && selectedProvider === PROVIDER_TYPES.WHATSAPP
          "
        >
          <WhatsappEmbeddedSignup />

          <div class="pt-6 mt-6 border-t border-n-weak">
            <p class="text-sm text-n-slate-11">
              {{ manualFallbackParts.prefix }}
              <a
                href="#"
                class="underline text-n-brand"
                @click.prevent="handleManualLinkClick"
              >
                {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_LINK_TEXT') }}
              </a>
              {{ manualFallbackParts.suffix }}
            </p>
          </div>
        </div>

        <CloudWhatsapp v-else-if="shouldShowCloudWhatsapp(selectedProvider)" />

        <Twilio
          v-else-if="selectedProvider === PROVIDER_TYPES.TWILIO"
          type="whatsapp"
        />
        <ThreeSixtyDialogWhatsapp
          v-else-if="selectedProvider === PROVIDER_TYPES.THREE_SIXTY_DIALOG"
        />
        <CloudWhatsapp v-else />
      </div>
    </div>
  </div>
</template>
