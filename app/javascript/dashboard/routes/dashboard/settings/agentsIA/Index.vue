<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import ModalAgentAdd from './components/ModalAgentAdd.vue';
import { useAlert } from 'dashboard/composables';
import AgentBotsAPI from '../../../../api/agentBots';
import InfoModal from '../../../../components/widgets/modal/InfoModal.vue';

export default {
  name: 'AgentsIa',
  components: { Spinner, ModalAgentAdd , InfoModal },
  data() {
    return {
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      showAddAgent: false,
      showDeleteModal: false,
      agentSelected: undefined,
      exceededLimit: true,
      showAlertLimit: false
    }
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    agentList() { return this.$store.getters['agentBots/getBots'] },
    isFetching() { return this.uiFlags.isFetching },
    isDeleting() { return this.uiFlags.isDeleting },
    hasAgentSelectedInboxes(){
      return this.agentSelected && this.agentSelected.inboxes.length
    },
    messageAgentTitle() {
      if (this.hasAgentSelectedInboxes) {
        return this.$t("AGENTS_AI.MODALS.AGENT.DELETE.NO_ALLOWED")
      }
      return this.$t("AGENTS_AI.MODALS.AGENT.DELETE.CONFIRM")
    },
    messageAgentSelected() {
      let item = this.agentSelected && this.agentSelected.name
      return this.$t("AGENTS_AI.MODALS.AGENT.DELETE.QUESTION", { item })
    },
    messageAgentInboxes() {
      return this.$t("AGENTS_AI.MODALS.AGENT.DELETE.INBOXES")
    }
  },
  mounted() { this.$store.dispatch('agentBots/get') },
  methods: {
    async openAddAgent() {
      await this.verifyLimitAgentBot()
      if (this.exceededLimit) {
        this.showAlertLimit = true
        return
      }
      this.showAddAgent = true
    },
    hideAddAgent() {
      this.showAddAgent = false
    },
    openDeleteModal(agent){
      this.agentSelected = agent
      this.showDeleteModal = true
    },
    closeDeleteModal(){
      this.agentSelected = undefined
      this.showDeleteModal = false
    },
    async confirmDeleteAgent() {
      if (!this.agentSelected) return
      try {
        await this.$store.dispatch('agentBots/delete', this.agentSelected.id);
        useAlert(this.$t('AGENTS_AI.MODALS.AGENT.DELETE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('AGENTS_AI.MODALS.AGENT.DELETE.FAIL'));
        console.warn({ error })
      } finally {
        this.showDeleteModal = false
        this.agentSelected = undefined
      }
    },
    goToCapabilities(agentId) {
      this.$router.push({
        path: 'capabilities',
        query: {
          agent: agentId
        }
      })
    },
    classOpacityAgent(agent) {
      return {
        'opacity-60': !agent.inboxes.length
      }
    },
    async verifyLimitAgentBot() {
      try {
        await AgentBotsAPI.limit_status()
        this.exceededLimit = false
      } catch (error) {
        this.exceededLimit = true
      }
    },
    hideAlertLimit() {
      this.showAlertLimit = false
    }
  }
}
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-8 overflow-auto">
    <woot-button color-scheme="success" class-names="button--fixed-top" icon="add-circle" @click="openAddAgent()">
      {{ $t('AGENTS_AI.BUTTON.ADD') }}
    </woot-button>
    <InfoModal 
      :title="$t('AGENTS_AI.PAYMENT.TITLE')"
      :show="showAlertLimit"
      @on-close="hideAlertLimit" 
    >
      {{ $t('AGENTS_AI.PAYMENT.MESSAGE') }}
      <a target="_blank" :href="$t('AGENTS_AI.PAYMENT.REFERENCE.REDIRECT')">
        {{ $t('AGENTS_AI.PAYMENT.REFERENCE.TITLE') }}
      </a>
    </InfoModal>
    <!-- MODALS  -->
    <woot-modal :show.sync="showAddAgent" :on-close="hideAddAgent">
      <ModalAgentAdd :on-close="hideAddAgent" />
    </woot-modal>
    <!-- MODALS  -->

    <div class="px-4 text-base">
      <p >{{ $t('AGENTS_AI.HEADER_INDEX.DESCRIPTION') }}</p>
    </div>

    <div class="px-4">
      <div v-if="isFetching" class="w-full flex justify-center items-center m-4">
        <Spinner />
      </div>
      <div v-else class="grid max-w-3xl grid-cols-2 mx-0 mt-6 sm:grid-cols-3 lg:grid-cols-4">
        <div v-for="a in agentList" :key="a.id" class="w-full h-full p-3 flex flex-col justify-between">
          <div @click="goToCapabilities(a.id)" class="relative w-full h-32 p-2 flex justify-center items-center cursor-pointer" :class="classOpacityAgent(a)" >
            <small class="absolute top-1 right-1 rounded shadow font-semibold px-2">
              {{ a.inboxes.length }}
            </small>
            <img :src="a.avatar_url || avatarDefault" :alt="a.name" class="h-full object-cover rounded " />
          </div>
          <h1
            class="text-center font-bold text-slate-700 dark:text-slate-100 border border-solid border-slate-25 dark:border-slate-800 rounded "
            :class="classOpacityAgent(a)"
          >
            {{ a.name }}
          </h1>
          <p 
            class="px-2 mb-0 mt-1 leading-normal text-center text-[12px] text-slate-700 dark:text-slate-100"
            :class="classOpacityAgent(a)"
          >
            {{ a.description }}
          </p>
          <div class="flex items-center justify-center w-full mt-0.5 gap-2">
            <woot-button
              v-tooltip="$t('AGENTS_AI.MODALS.AGENT.DELETE.TOOLTIP')"
              icon="delete"
              variant="smooth"
              size="small"
              color-scheme="alert"
              @click="openDeleteModal(a)"
            />
          </div>
        </div>
      </div>
    </div>
    <woot-modal
      :show.sync="showDeleteModal"
      :on-close="closeDeleteModal"
      size="small"
    >
      <div class="pt-8 pl-8">
        <h2 class="text-base font-semibold leading-6 text-slate-800 dark:text-slate-50">
          {{ messageAgentTitle }}
        </h2>
        <p v-if="hasAgentSelectedInboxes" class="w-full mt-2 mb-8 text-sm leading-5 break-words text-slate-600 dark:text-slate-300">
          {{ messageAgentInboxes }}
          <ul class="list-none mb-3 mt-1">
            <li v-for="inbox in agentSelected.inboxes" :key="inbox.id">
              <small class="font-semibold">{{ inbox.name }}</small>
            </li>
          </ul>
        </p>
        <p v-else class="w-full mt-2 text-sm leading-5 break-words text-slate-600 dark:text-slate-300">
          {{ messageAgentSelected }}
        </p>
        <div v-if="!hasAgentSelectedInboxes" class="flex items-center justify-end gap-2 p-8">
          <button @click="closeDeleteModal" type="submit" class="button action-button clear primary">
            <span class="button__content text-left rtl:text-right">{{ $t("AGENTS_AI.MODALS.AGENT.DELETE.ACTION.CANCEL")  }}</span>
          </button> 
          <button :disabled="isDeleting"  @click="confirmDeleteAgent" type="submit" class="button action-button smooth alert">
            <Spinner v-if="isDeleting" />
            <span class="button__content text-left rtl:text-right">{{ $t("AGENTS_AI.MODALS.AGENT.DELETE.ACTION.OK")  }}</span>
          </button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
