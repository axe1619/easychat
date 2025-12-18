<script>
import ChannelItem from 'dashboard/components/widgets/ChannelItem.vue';

export default {
  components: {
    ChannelItem,
  },
  data() {
    return {
      enabledFeatures: {},
    };
  },
  computed: {
    accountId() {
      return this.$store.getters.getCurrentAccountId;
    },
    currentAccount() {
      return this.$store.getters.getCurrentAccount || {};
    },
    globalConfig() {
      return this.$store.getters['globalConfig/get'] || {};
    },
    hasTiktokConfigured() {
      return Boolean(window.chatwootConfig?.tiktokAppId);
    },
    channelList() {
      const { apiChannelName } = this.globalConfig;
      const channels = [
        {
          key: 'website',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.DESCRIPTION'),
          icon: 'i-woot-website',
        },
        {
          key: 'facebook',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.DESCRIPTION'),
          icon: 'i-woot-messenger',
        },
        {
          key: 'whatsapp',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.DESCRIPTION'),
          icon: 'i-woot-whatsapp',
        },
        {
          key: 'sms',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.SMS.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.SMS.DESCRIPTION'),
          icon: 'i-woot-sms',
        },
        {
          key: 'email',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.EMAIL.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.EMAIL.DESCRIPTION'),
          icon: 'i-woot-mail',
        },
        {
          key: 'api',
          title: apiChannelName || this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.API.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.API.DESCRIPTION'),
          icon: 'i-woot-api',
        },
        {
          key: 'telegram',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.DESCRIPTION'),
          icon: 'i-woot-telegram',
        },
        {
          key: 'line',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.DESCRIPTION'),
          icon: 'i-woot-line',
        },
        {
          key: 'instagram',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE'),
          description: this.$t(
            'INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.DESCRIPTION'
          ),
          icon: 'i-woot-instagram',
        },
      ];

      if (this.hasTiktokConfigured) {
        channels.push({
          key: 'tiktok',
          title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.TITLE'),
          description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.DESCRIPTION'),
          icon: 'i-woot-tiktok',
        });
      }

      channels.push({
        key: 'voice',
        title: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.VOICE.TITLE'),
        description: this.$t('INBOX_MGMT.ADD.AUTH.CHANNEL.VOICE.DESCRIPTION'),
        icon: 'i-ri-phone-fill',
      });

      return channels;
    },
  },
  mounted() {
    this.enabledFeatures = this.currentAccount.features || {};
  },
  methods: {
    initChannelAuth(channel) {
      this.$router.push({
        name: 'settings_inboxes_page_channel',
        params: {
          sub_page: channel,
          accountId: this.accountId,
        },
      });
    },
  },
};
</script>

<template>
  <div class="w-full p-8 overflow-auto">
    <div class="grid max-w-3xl grid-cols-1 xs:grid-cols-2 mx-0 gap-6 sm:grid-cols-3">
      <ChannelItem
        v-for="channel in channelList"
        :key="channel.key"
        :channel="channel"
        :enabled-features="enabledFeatures"
        @channel-item-click="initChannelAuth"
      />
    </div>
  </div>
</template>
