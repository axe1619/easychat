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
      showAlertLimit: false,
      showInboxesTooltip: false,
      agentForTooltip: null,
      tooltipPosition: { x: 0, y: 0 }
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
    },
    showInboxesList(agent, event) {
      event.stopPropagation();
      if (agent.inboxes && agent.inboxes.length > 0) {
        this.agentForTooltip = agent;
        this.tooltipPosition = {
          x: event.clientX,
          y: event.clientY
        };
        this.showInboxesTooltip = true;
      }
    },
    closeInboxesTooltip() {
      this.showInboxesTooltip = false;
      this.agentForTooltip = null;
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
          <div @click="goToCapabilities(a.id)" class="relative w-full h-32 p-2 flex flex-col justify-center items-center cursor-pointer bg-white dark:bg-slate-900 border border-solid border-slate-200 dark:border-slate-800 hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md transition-all duration-200 ease-in" :class="classOpacityAgent(a)" >
            <div 
              @click.stop="showInboxesList(a, $event)"
              class="absolute top-2 right-2 rounded shadow font-semibold px-2 py-1 text-xs bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-100 cursor-pointer border border-solid border-slate-200 dark:border-slate-800 hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md transition-all duration-200 ease-in z-10"
            >
              {{ $t('AGENTS_AI.INBOXES_COUNT', { count: a.inboxes.length }) }}
            </div>
            <img :src="a.avatar_url || avatarDefault" :alt="a.name" class="h-full object-cover mt-2" />
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

    <!-- Tooltip/Modal de Inboxes -->
    <woot-modal
      v-if="showInboxesTooltip && agentForTooltip"
      :show.sync="showInboxesTooltip"
      :on-close="closeInboxesTooltip"
      size="small"
    >
      <div class="pt-3 pl-3 pr-3 pb-2">
        <h2 class="text-sm font-semibold leading-5 text-slate-800 dark:text-slate-50 mb-3">
          {{ $t('AGENTS_AI.INBOXES_LIST.TITLE', { agentName: agentForTooltip.name }) }}
        </h2>
        <div v-if="agentForTooltip.inboxes && agentForTooltip.inboxes.length > 0" class="max-h-64 overflow-y-auto">
          <ul class="list-none space-y-1.5">
            <li 
              v-for="inbox in agentForTooltip.inboxes" 
              :key="inbox.id"
              class="p-1.5 rounded border border-slate-200 dark:border-slate-700"
            >
              <span class="text-sm font-medium text-slate-700 dark:text-slate-100">{{ inbox.name }}</span>
            </li>
          </ul>
        </div>
        <p v-else class="text-xs text-slate-600 dark:text-slate-300">
          {{ $t('AGENTS_AI.INBOXES_LIST.EMPTY') }}
        </p>
        <div class="flex items-center justify-end gap-2 pt-3 pb-1">
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            size="small"
            @click="closeInboxesTooltip"
          >
            {{ $t('AGENTS_AI.MODALS.SANDBOX.CLOSE') }}
          </woot-button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
