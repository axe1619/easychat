<script>
import { mapGetters } from 'vuex';
import MessageTable from '../../conversation/MessageTable.vue';
import CampaignsAPI from '../../../../api/campaigns'
export default {
    components: {
        MessageTable
    },
    data() {
        return {
            campaign: undefined,
            messages: undefined,
            state: "success",
            loading: {
                messages: false
            }
        }
    },
    watch: {
        '$route.params.campaignId'(value) {
            if (!value) return
            this.loadCampaign(value)
            this.loadCampaignMessage(this.campaign.id, this.state)
        }
    },
    computed: {
        ...mapGetters({
            accountId: 'getCurrentAccountId',
            getCampaigns: "campaigns/getCampaigns",
        }),
        title() {
            return this.campaign?.title || "..."
        },
        reach() {
            return this.campaign?.reach || 0
        },
        messageSuccess() {
            return this.campaign?.message_success || 0
        },
        messagePending() {
            return this.campaign?.message_pending || 0
        },
        messageFailed() {
            if (!this.campaign)
                return 0
            const { reach, message_success, message_pending } = this.campaign
            if (!reach || !message_success || !message_pending)
                return 0
            return Number(reach - (message_success + message_pending))
        }
    },
    methods: {
        onSelectState() {
            this.loadCampaignMessage(this.campaign.id, this.state)
        },
        loadCampaign(campaignId) {
            this.campaign = this.getCampaigns("one_off").find((campaign) => campaign.id == campaignId)
        },
        async loadCampaignMessage(id, state) {
            this.loading.messages = true
            const response = await CampaignsAPI.getContacts(id, state)
            this.messages = response.data
            this.loading.messages = false
        },
        initialize() {
            this.loadCampaign(this.$route.params.campaignId)
            if (!this.campaign) {
                this.$router.push({ name: "one_off", params: { accountId: this.accountId } });
                return
            }
            this.loadCampaignMessage(this.campaign.id, this.state)
        }
    },
    mounted() {
        this.initialize()
    }
}
</script>
<template>
    <div class="flex-1 p-4 overflow-auto">
        <div class="px-5 py-4 mb-2 bg-white border rounded-md dark:bg-slate-800 border-slate-50 dark:border-slate-900">
            <h3 class="text-xl my-3">{{ title }}</h3>
            <div class="flex">
                <div class="flex gap-2">
                    <select v-model="state" class="input-select" @change="onSelectState">
                        <option v-for="item in ['SUCCESS','PENDING','FAILED']" :key="item" :value="item.toLowerCase()">
                            {{$t(`CAMPAIGN.ONE_OFF.STATES.${item}.TEXT`)}}
                        </option>
                    </select>
                </div>
                <div class="flex flex-1 gap-3 justify-end">
                    <woot-label 
                        small 
                        :title="$t('CAMPAIGN.ONE_OFF.STATES.SCOPE.VALUE', { scope: this.reach })"
                        color-scheme="primary" 
                        class="mr-3 text-xs" 
                    />
                    <woot-label 
                        small 
                        :title="$t('CAMPAIGN.ONE_OFF.STATES.PENDING.VALUE', { amount: this.messagePending })"
                        color-scheme="warning" 
                        class="mr-3 text-xs" 
                    />
                    <woot-label 
                        small 
                        :title="$t('CAMPAIGN.ONE_OFF.STATES.SUCCESS.VALUE', { amount: this.messageSuccess })"
                        color-scheme="success" 
                        class="mr-3 text-xs" 
                    />
                    <woot-label 
                        small 
                        :title="$t('CAMPAIGN.ONE_OFF.STATES.FAILED.VALUE', { amount: this.messageFailed })"
                        color-scheme="alert" 
                        class="mr-3 text-xs" 
                    />
                </div>
            </div>
            <div>
                <MessageTable
                 :messages="messages"
                 :accountId="accountId"
                 :is-loading="loading.messages"
                />
            </div>
        </div>
    </div>
</template>

<style>
.input-select {
    flex: 3;
}

.input-search {
    flex: 7;
}
</style>