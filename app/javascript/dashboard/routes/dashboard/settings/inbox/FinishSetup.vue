<script>
import QRCode from 'qrcode';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import EmailInboxFinish from './channels/emailChannels/EmailInboxFinish.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export default {
  components: {
    EmptyState,
    NextButton,
    DuplicateInboxBanner,
    EmailInboxFinish,
  },
  data() {
    return {
      qrCodes: {
        whatsapp: '',
        messenger: '',
        telegram: '',
      },
    };
  },
  computed: {
    currentInbox() {
      return (
        this.$store.getters['inboxes/getInbox'](this.$route.params.inbox_id) ||
        {}
      );
    },
    isATwilioChannel() {
      return this.currentInbox?.channel_type === INBOX_TYPES.TWILIO;
    },
    isATwilioWhatsAppChannel() {
      return this.isATwilioChannel && this.currentInbox?.medium === 'whatsapp';
    },
    isASmsInbox() {
      return (
        this.currentInbox?.channel_type === INBOX_TYPES.SMS ||
        (this.isATwilioChannel && this.currentInbox?.medium === 'sms')
      );
    },
    isALineChannel() {
      return this.currentInbox?.channel_type === INBOX_TYPES.LINE;
    },
    isAnEmailChannel() {
      return this.currentInbox?.channel_type === INBOX_TYPES.EMAIL;
    },
    isAWhatsAppChannel() {
      return (
        this.currentInbox?.channel_type === INBOX_TYPES.WHATSAPP ||
        this.isATwilioWhatsAppChannel
      );
    },
    isAFacebookInbox() {
      return this.currentInbox?.channel_type === INBOX_TYPES.FB;
    },
    isATelegramChannel() {
      return this.currentInbox?.channel_type === INBOX_TYPES.TELEGRAM;
    },
    isAWhatsAppCloudChannel() {
      return (
        this.currentInbox?.channel_type === INBOX_TYPES.WHATSAPP &&
        this.currentInbox?.provider === 'whatsapp_cloud'
      );
    },
    shouldShowWhatsAppWebhookDetails() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.currentInbox?.provider_config?.source !== 'embedded_signup'
      );
    },
    isWhatsAppEmbeddedSignup() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.currentInbox?.provider_config?.source === 'embedded_signup'
      );
    },
    hasDuplicateInstagramInbox() {
      const instagramId = this.currentInbox?.instagram_id;
      const facebookInbox =
        this.$store.getters['inboxes/getFacebookInboxByInstagramId'](
          instagramId
        );

      return (
        this.currentInbox?.channel_type === INBOX_TYPES.INSTAGRAM &&
        facebookInbox
      );
    },
    message() {
      if (this.isATwilioChannel) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isASmsInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isALineChannel) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAWhatsAppCloudChannel && this.shouldShowWhatsAppWebhookDetails) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.currentInbox?.web_widget_script) {
        return this.$t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
      }

      if (this.isWhatsAppEmbeddedSignup) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
        )}`;
      }

      return this.$t('INBOX_MGMT.FINISH.MESSAGE');
    },
  },
  watch: {
    currentInbox: {
      handler(newInbox) {
        if (newInbox) {
          this.generateQRCodes();
        }
      },
      immediate: true,
    },
  },
  mounted() {
    this.generateQRCodes();
  },
  methods: {
    async generateQRCode(platform, identifier) {
      if (!identifier || !identifier.trim()) {
        // eslint-disable-next-line no-console
        console.warn(`Invalid identifier for ${platform} QR code`);
        return;
      }

      try {
        const platformUrls = {
          whatsapp: id => `https://wa.me/${id}`,
          messenger: id => `https://m.me/${id}`,
          telegram: id => `https://t.me/${id}`,
        };

        const url = platformUrls[platform](identifier);
        const qrDataUrl = await QRCode.toDataURL(url);
        this.qrCodes[platform] = qrDataUrl;
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error(`Error generating ${platform} QR code:`, error);
        this.qrCodes[platform] = '';
      }
    },
    async generateQRCodes() {
      if (!this.currentInbox) return;

      if (this.currentInbox.phone_number && this.isAWhatsAppChannel) {
        const phoneNumber = this.currentInbox.phone_number.replace(
          'whatsapp:',
          ''
        );
        await this.generateQRCode('whatsapp', phoneNumber);
      }

      if (this.currentInbox.page_id && this.isAFacebookInbox) {
        await this.generateQRCode('messenger', this.currentInbox.page_id);
      }

      if (this.isATelegramChannel && this.currentInbox.bot_name) {
        await this.generateQRCode('telegram', this.currentInbox.bot_name);
      }
    },
  },
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <DuplicateInboxBanner
      v-if="hasDuplicateInstagramInbox"
      :content="$t('INBOX_MGMT.ADD.INSTAGRAM.NEW_INBOX_SUGGESTION')"
    />
    <EmptyState
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="isAnEmailChannel && !currentInbox.provider ? '' : message"
      :button-text="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <div class="my-4 mx-auto max-w-[70%]">
          <woot-code
            v-if="currentInbox.web_widget_script"
            :script="currentInbox.web_widget_script"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isATwilioWhatsAppChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="shouldShowWhatsAppWebhookDetails"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <p class="mt-8 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="mt-8 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_VERIFICATION_TOKEN') }}
          </p>
          <woot-code
            lang="html"
            :script="currentInbox.provider_config.webhook_verify_token"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isALineChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isASmsInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <EmailInboxFinish
          v-if="isAnEmailChannel && !currentInbox.provider"
          :inbox="currentInbox"
          :inbox-id="$route.params.inbox_id"
        />
        <div
          v-if="isAWhatsAppChannel && qrCodes.whatsapp"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.whatsapp"
              alt="WhatsApp QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isAFacebookInbox && qrCodes.messenger"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.messenger"
              alt="Messenger QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isATelegramChannel && qrCodes.telegram"
          class="flex flex-col gap-4 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
          </p>

          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.telegram"
              alt="Telegram QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div class="flex gap-2 justify-center mt-4">
          <router-link
            :to="{
              name: 'settings_inbox_show',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton outline slate :label="$t('INBOX_MGMT.FINISH.MORE_SETTINGS')" />
          </router-link>
          <router-link
            :to="{
              name: 'inbox_dashboard',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton solid teal :label="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')" />
          </router-link>
        </div>
      </div>
    </EmptyState>
  </div>
</template>
