<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { useAlert } from 'dashboard/composables';
import AgentBotsAPI from '../../../../api/agentBots';
import InfoModal from '../../../../components/widgets/modal/InfoModal.vue';

export default {
  name: 'AgentsIa',
  components: { Spinner, InfoModal },
  data() {
    return {
        avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      showDeleteModal: false,
      agentSelected: undefined,
      exceededLimit: true,
      showAlertLimit: false,
      searchQuery: '',
      showMenuForAgent: null,
    }
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
      accountId: 'getCurrentAccountId',
      currentAccount: 'accounts/getAccount',
    }),
    agentList() { return this.$store.getters['agentBots/getBots'] },
    isFetching() { return this.uiFlags.isFetching },
    isDeleting() { return this.uiFlags.isDeleting },
    currentAccountData() {
      return this.currentAccount(this.accountId);
    },
    activeAgents() {
      return this.agentList.filter(agent => this.isAgentActive(agent));
    },
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
    },
    filteredAgentList() {
      if (!this.searchQuery) {
        return this.agentList;
      }
      const query = this.searchQuery.toLowerCase();
      return this.agentList.filter(agent => 
        agent.name.toLowerCase().includes(query) ||
        (agent.description && agent.description.toLowerCase().includes(query))
      );
    }
  },
  async mounted() { 
    await this.$store.dispatch('agentBots/get');
    // Cargar cuenta si no está cargada
    if (!this.currentAccountData || !this.currentAccountData.id) {
      await this.$store.dispatch('accounts/get');
    }

    // Cerrar menú al hacer clic fuera
    document.addEventListener('click', this.handleDocumentClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleDocumentClick);
  },
  methods: {
    async openAddAgent() {
      await this.verifyLimitAgentBot();
      if (this.exceededLimit) {
        this.showAlertLimit = true;
        return;
      }
      this.$router.push({ name: 'settings_agents_ia_templates' });
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
    goToKnowledgeSources() {
      // Funcionalidad deshabilitada por el momento
      return;
    },
    editAgent(agentId) {
      this.goToCapabilities(agentId);
    },
    isAgentActive(agent) {
      // Un agente está activo si tiene inboxes asignados
      const hasInboxes = agent.inboxes && agent.inboxes.length > 0;
      return hasInboxes;
    },
    toggleMenu(agentId) {
      this.showMenuForAgent = this.showMenuForAgent === agentId ? null : agentId;
    },
    closeMenu() {
      this.showMenuForAgent = null;
    },
    handleMenuAction(action, agent) {
      this.closeMenu();
      if (action === 'delete') {
        this.openDeleteModal(agent);
      }
    },
    handleDocumentClick(event) {
      if (this.showMenuForAgent && !event.target.closest('.menu-container')) {
        this.closeMenu();
      }
    }
  }
}
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-8 overflow-auto">
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

    <div class="px-4 text-base mb-6">
      <p>{{ $t('AGENTS_AI.HEADER_INDEX.DESCRIPTION') }}</p>
    </div>

    <!-- Header con botones y búsqueda -->
    <div class="flex items-center justify-between mb-6 px-4">
      <div class="flex items-center gap-3">
        <woot-button 
          color-scheme="primary" 
          icon="add-circle" 
          @click="openAddAgent()"
        >
          {{ $t('AGENTS_AI.CREATE.TITLE') }}
        </woot-button>
      </div>
      <div class="flex items-center gap-3">
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            :placeholder="$t('AGENTS_AI.SEARCH.PLACEHOLDER')"
            class="px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-woot-500"
          />
        </div>
      </div>
    </div>



    <!-- Grid de agentes -->
    <div class="px-4">
      <div v-if="isFetching" class="w-full flex justify-center items-center m-4">
        <Spinner />
      </div>
      <div v-else class="grid max-w-6xl grid-cols-1 mx-0 mt-6 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- Cards de agentes existentes -->
        <div 
          v-for="a in filteredAgentList" 
          :key="a.id" 
          class="relative bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 p-6 flex flex-col min-h-[300px]"
        >
          <!-- Labels de estado -->
          <div class="absolute top-3 left-3 z-10 flex flex-wrap gap-2">
           
            <span v-if="isAgentActive(a)" class="bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.ACTIVE') }}
            </span>
            <span v-if="!isAgentActive(a)" class="bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.INACTIVE') }}
            </span>

          </div>
          
          <!-- Avatar/Icono - Centrado verticalmente en la parte superior -->
          <div class="flex justify-center items-center mb-4 mt-2 h-20">
            <img 
              :src="a.avatar_url || avatarDefault" 
              :alt="a.name" 
              class="max-h-full max-w-full object-contain"
            />
          </div>
          
          <!-- Título -->
          <h3 class="text-lg font-bold text-slate-800 dark:text-slate-100 mb-2">
            {{ a.name }}
          </h3>
          
          <!-- Descripción -->
          <p class="text-sm text-slate-600 dark:text-slate-300 mb-4 flex-1 min-h-[3rem]">
            {{ a.description || '' }}
          </p>
          
          <!-- Botones inferiores -->
          <div class="flex items-center justify-between mt-auto pt-4 border-t border-slate-200 dark:border-slate-700">
            <div class="flex items-center gap-2 relative menu-container">
              <woot-button
                icon="edit"
                variant="smooth"
                color-scheme="secondary"
                size="small"
                @click.stop="editAgent(a.id)"
              >
                {{ $t('AGENTS_AI.CARD.EDIT') }}
              </woot-button>
              <button
                @click.stop="toggleMenu(a.id)"
                class="p-1 rounded hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              >
                <fluent-icon icon="more-vertical" size="18" class="text-slate-600 dark:text-slate-300" />
              </button>
              <div
                v-if="showMenuForAgent === a.id"
                @click.stop
                class="absolute bottom-full left-0 mb-2 w-48 bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-slate-200 dark:border-slate-700 z-20"
              >
                <div class="py-1">

                  <button
                    @click="handleMenuAction('delete', a)"
                    class="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2"
                  >
                    <fluent-icon icon="delete" size="16" />
                    {{ $t('AGENTS_AI.CARD.MENU.DELETE') }}
                  </button>
                </div>
              </div>
            </div>

          </div>
        </div>

        <!-- Card de Crear nuevo Agente IA -->
        <div 
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 p-6 flex flex-col items-center justify-center cursor-pointer hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md transition-all duration-200"
          @click="openAddAgent"
        >
          <div class="flex flex-col items-center justify-center h-full">
            <h3 class="text-lg font-bold text-slate-800 dark:text-slate-100 mb-2 text-center">
              {{ $t('AGENTS_AI.CARD.CREATE_NEW.TITLE') }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4 text-center">
              {{ $t('AGENTS_AI.CARD.CREATE_NEW.DESCRIPTION') }}
            </p>
            <woot-button
              icon="add-circle"
              variant="smooth"
              color-scheme="secondary"
              size="small"
            >
              {{ $t('AGENTS_AI.CARD.CREATE_NEW.BUTTON') }}
            </woot-button>
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
