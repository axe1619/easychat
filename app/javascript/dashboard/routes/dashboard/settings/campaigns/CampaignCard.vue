<script>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { messageStamp } from 'shared/helpers/timeHelper';
import { intervalToDuration } from 'date-fns';

export default {
  components: {
    UserAvatarWithName,
    InboxName,
  },
  mixins: [messageFormatterMixin],
  props: {
    campaign: {
      type: Object,
      required: true,
    },
    isOngoingType: {
      type: Boolean,
      default: true,
    },
  },

  computed: {
    campaignStatus() {
      if (this.isOngoingType) {
        return this.campaign.enabled
          ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
          : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
      }

      return this.campaign.campaign_status === 'completed'
        ? this.$t('CAMPAIGN.LIST.STATUS.COMPLETED')
        : this.$t('CAMPAIGN.LIST.STATUS.ACTIVE');
    },
    colorScheme() {
      if (this.isOngoingType) {
        return this.campaign.enabled ? 'success' : 'secondary';
      }
      return this.campaign.campaign_status === 'completed'
        ? 'secondary'
        : 'success';
    },
    campaignReach() {
      return this.campaign.reach || 0
    },
    campaignDuration() {
      if (!this.campaign.duration)
        return "-m, -s"
      const duration = intervalToDuration({ start: 0, end: this.campaign.duration * 1000 })
      return `${duration.minutes}m, ${duration.seconds}s`
    },
    campaignMessageSuccess() {
      return this.campaign.message_success || 0
    },
    campaigMessagePending(){
      return this.campaign.message_pending || 0
    },
    campaignMessageFailed() {
      const reach = Number(this.campaign.reach)
      const success = Number(this.campaign.message_success)
      const pending = Number(this.campaign.message_pending)
      if (!Number.isFinite(reach) || !Number.isFinite(success) || !Number.isFinite(pending)) {
        return 0
      }
      return Number(reach - (success + pending))
    }
  },
  methods: {
    messageStamp,
    toNavigateCampaignDetail() {
      this.$router.push({
        name: 'one_off_detail',
        params: { campaignId: this.campaign.id }
      })
    }
  },
};
</script>

<template>
  <div
    class="px-5 py-4 mb-2 bg-white border rounded-md dark:bg-slate-800 border-slate-50 dark:border-slate-900"
  >
    <div class="flex flex-row items-start justify-between">
      <div class="flex flex-col">
        <div
          class="mb-1 -mt-1 text-base font-medium text-slate-900 dark:text-slate-100"
        >
          {{ campaign.title }}
        </div>
        <div
          v-dompurify-html="formatMessage(campaign.message)"
          class="text-sm line-clamp-1 [&>p]:mb-0"
        />
      </div>
      <div class="flex flex-row space-x-4">
        <woot-button
          v-if="isOngoingType"
          variant="link"
          icon="edit"
          color-scheme="secondary"
          size="small"
          @click="$emit('edit', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.EDIT') }}
        </woot-button>
        <woot-button
          v-if="!isOngoingType"
          variant="link"
          icon="eye-show"
          color-scheme="secondary"
          size="small"
          @click="toNavigateCampaignDetail"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.DETAIL') }}
        </woot-button>
        <woot-button
          variant="link"
          icon="dismiss-circle"
          size="small"
          color-scheme="secondary"
          @click="$emit('delete', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.DELETE') }}
        </woot-button>
      </div>
    </div>

    <div class="flex flex-row items-center mt-5 space-x-3 justify-between">
     <div class="flex flex-row items-center space-x-3">
       <woot-label
         small
         :title="campaignStatus"
         :color-scheme="colorScheme"
         class="mr-3 text-xs"
       />
       <InboxName :inbox="campaign.inbox" class="mb-1 ltr:ml-0 rtl:mr-0" />
       <UserAvatarWithName
         v-if="campaign.sender"
         :user="campaign.sender"
         class="mb-1"
       />
       <div
         v-if="campaign.trigger_rules.url"
         class="w-1/4 mb-1 text-xs text-woot-600 text-truncate"
       >
         {{ campaign.trigger_rules.url }}
       </div>
       <div
         v-if="campaign.scheduled_at"
         class="mb-1 text-xs text-slate-700 dark:text-slate-500"
       >
         {{ messageStamp(new Date(campaign.scheduled_at), 'LLL d, h:mm a') }}
       </div>
     </div>
     <div class="flex flex-row items-center space-x-3">
        <woot-label
          v-if="!isOngoingType"
          :title="$t('CAMPAIGN.ONE_OFF.STATES.TIME.VALUE', { time: campaignDuration })"
          color-scheme="secondary"
          class="mr-3 tag"
        />
        <woot-label
          :title="$t('CAMPAIGN.ONE_OFF.STATES.SCOPE.VALUE', { scope: campaignReach })"
          color-scheme="primary"
          class="mr-3 tag"
        />
        <woot-label
          :title="$t('CAMPAIGN.ONE_OFF.STATES.PENDING.VALUE', { amount: campaigMessagePending })"
          color-scheme="warning"
          class="mr-3 tag"
        />
        <woot-label
          v-if="!isOngoingType"
          :title="$t('CAMPAIGN.ONE_OFF.STATES.SUCCESS.VALUE', { amount: campaignMessageSuccess })"
          color-scheme="success"
          class="mr-3 tag"
        />
        <woot-label
          v-if="!isOngoingType"
          :title="$t('CAMPAIGN.ONE_OFF.STATES.FAILED.VALUE', { amount: campaignMessageFailed })"
          color-scheme="alert"
          class="mr-3 tag"
        />
     </div>
    </div>
  </div>
</template>
<style lang="scss" scoped>
  .tag{
    font-size: 10px;
  }
</style>