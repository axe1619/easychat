<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import ModalAgentAdd from './components/ModalAgentAdd.vue';
import { useAlert } from 'dashboard/composables';
import AgentBotsAPI from '../../../../api/agentBots';
import InfoModal from '../../../../components/widgets/modal/InfoModal.vue';
import SwitchButton from 'dashboard/components/ui/Switch.vue';

export default {
  name: 'AgentsIa',
  components: { Spinner, ModalAgentAdd, InfoModal, SwitchButton },
  data() {
    return {
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      showAddAgent: false,
      showDeleteModal: false,
      agentSelected: undefined,
      exceededLimit: true,
      showAlertLimit: false,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      showInboxesTooltip: false,
      agentForTooltip: null,
      tooltipPosition: { x: 0, y: 0 }
=======
=======
>>>>>>> Stashed changes
      searchQuery: '',
      defaultAgentId: null,
      showDefaultAgentModal: false,
      selectedDefaultAgentId: null,
      showMenuForAgent: null,
      agentEnabledStatus: {} // Almacena el estado enabled de cada agente
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
    this.loadDefaultAgent();
    // Inicializar estados enabled de agentes (por defecto todos activos)
    this.agentList.forEach(agent => {
      // Si el agente tiene inboxes, está habilitado por defecto
      const hasInboxes = agent.inboxes && agent.inboxes.length > 0;
      this.$set(this.agentEnabledStatus, agent.id, hasInboxes);
    });
    // Cerrar menú al hacer clic fuera
    document.addEventListener('click', this.handleDocumentClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleDocumentClick);
  },
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
=======
>>>>>>> Stashed changes
    goToKnowledgeSources() {
      // Funcionalidad deshabilitada por el momento
      return;
    },
    editAgent(agentId) {
      this.goToCapabilities(agentId);
    },
    async toggleAgentStatus(agent) {
      const newStatus = !this.agentEnabledStatus[agent.id];
      this.$set(this.agentEnabledStatus, agent.id, newStatus);
      
      try {
        // Actualizar el agente con el nuevo estado enabled en bot_config o custom_attributes
        // Por ahora, solo actualizamos el estado local
        // TODO: Cuando se agregue el campo enabled al modelo, descomentar:
        // await this.$store.dispatch('agentBots/update', {
        //   id: agent.id,
        //   enabled: newStatus
        // });
        
        // Si se desactiva y es el agente predeterminado, limpiarlo
        if (!newStatus && this.defaultAgentId === agent.id) {
          this.defaultAgentId = null;
          await this.saveDefaultAgent();
        }
        
        useAlert(newStatus ? this.$t('AGENTS_AI.CARD.ENABLED_SUCCESS') : this.$t('AGENTS_AI.CARD.DISABLED_SUCCESS'));
      } catch (error) {
        // Revertir el estado en caso de error
        this.$set(this.agentEnabledStatus, agent.id, !newStatus);
        useAlert(this.$t('AGENTS_AI.CARD.TOGGLE_ERROR'));
        console.warn('Error toggling agent status:', error);
      }
    },
    isAgentActive(agent) {
      // Un agente está activo si tiene inboxes asignados Y está habilitado
      const isEnabled = this.agentEnabledStatus[agent.id] !== false;
      const hasInboxes = agent.inboxes && agent.inboxes.length > 0;
      return isEnabled && hasInboxes;
    },
    isDefaultAgent(agent) {
      return this.defaultAgentId === agent.id;
    },
    async loadDefaultAgent() {
      try {
        const account = this.currentAccountData;
        if (account && account.custom_attributes && account.custom_attributes.default_agent_bot_id) {
          this.defaultAgentId = account.custom_attributes.default_agent_bot_id;
        }
      } catch (error) {
        console.warn('Error loading default agent:', error);
      }
    },
    openDefaultAgentModal() {
      this.selectedDefaultAgentId = this.defaultAgentId;
      this.showDefaultAgentModal = true;
    },
    closeDefaultAgentModal() {
      this.showDefaultAgentModal = false;
      this.selectedDefaultAgentId = null;
    },
    async saveDefaultAgent() {
      try {
        const account = this.currentAccountData;
        const customAttributes = { ...(account.custom_attributes || {}) };
        customAttributes.default_agent_bot_id = this.selectedDefaultAgentId;
        
        await this.$store.dispatch('accounts/update', {
          custom_attributes: customAttributes
        });
        
        this.defaultAgentId = this.selectedDefaultAgentId;
        useAlert(this.$t('AGENTS_AI.MODALS.DEFAULT_AGENT.SUCCESS'));
        this.closeDefaultAgentModal();
      } catch (error) {
        useAlert(this.$t('AGENTS_AI.MODALS.DEFAULT_AGENT.ERROR'));
        console.warn('Error saving default agent:', error);
      }
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
      } else if (action === 'duplicate') {
        // Funcionalidad de duplicar aún no implementada
        useAlert(this.$t('AGENTS_AI.CARD.MENU.DUPLICATE_NOT_AVAILABLE'));
      }
    },
    handleDocumentClick(event) {
      if (this.showMenuForAgent && !event.target.closest('.menu-container')) {
        this.closeMenu();
      }
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
    <!-- MODALS  -->
    <woot-modal :show.sync="showAddAgent" :on-close="hideAddAgent">
      <ModalAgentAdd :on-close="hideAddAgent" />
    </woot-modal>
    <!-- MODALS  -->

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
          {{ $t('AGENTS_AI.BUTTON.ADD') }}
        </woot-button>
        <woot-button 
          variant="smooth"
          color-scheme="secondary"
        >
          {{ $t('AGENTS_AI.BUTTON.MANAGE_KNOWLEDGE_SOURCES') }}
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

    <!-- Sección de Agente IA predeterminado -->
    <div class="mb-6 px-4">
      <div class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 p-6 flex items-center justify-between">
        <div class="flex-1">
          <h2 class="text-lg font-semibold text-slate-800 dark:text-slate-100 mb-2">
            {{ $t('AGENTS_AI.DEFAULT_AGENT.TITLE') }}
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-300">
            {{ $t('AGENTS_AI.DEFAULT_AGENT.DESCRIPTION') }}
          </p>
        </div>
        <woot-button 
          variant="smooth"
          color-scheme="secondary"
          @click="openAddAgent"
        >
          {{ $t('AGENTS_AI.DEFAULT_AGENT.BUTTON') }}
        </woot-button>
      </div>
    </div>

    <!-- Grid de agentes -->
    <div class="px-4">
      <div v-if="isFetching" class="w-full flex justify-center items-center m-4">
        <Spinner />
      </div>
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
          
=======
      <div v-else class="grid max-w-6xl grid-cols-1 mx-0 mt-6 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- Cards de agentes existentes -->
        <div 
          v-for="a in filteredAgentList" 
          :key="a.id" 
          class="relative bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 p-6 flex flex-col min-h-[300px]"
        >
          <!-- Labels de estado -->
          <div class="absolute top-3 left-3 z-10 flex flex-wrap gap-2">
            <span v-if="isDefaultAgent(a)" class="bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.DEFAULT') }}
            </span>
            <span v-if="isAgentActive(a)" class="bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.ACTIVE') }}
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
=======
      <div v-else class="grid max-w-6xl grid-cols-1 mx-0 mt-6 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- Cards de agentes existentes -->
        <div 
          v-for="a in filteredAgentList" 
          :key="a.id" 
          class="relative bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 p-6 flex flex-col min-h-[300px]"
        >
          <!-- Labels de estado -->
          <div class="absolute top-3 left-3 z-10 flex flex-wrap gap-2">
            <span v-if="isDefaultAgent(a)" class="bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.DEFAULT') }}
            </span>
            <span v-if="isAgentActive(a)" class="bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-xs font-semibold px-2.5 py-1 rounded-full">
              {{ $t('AGENTS_AI.CARD.ACTIVE') }}
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
>>>>>>> Stashed changes
          
          <!-- Título -->
          <h3 class="text-lg font-bold text-slate-800 dark:text-slate-100 mb-2 text-center">
            {{ a.name }}
          </h3>
          
          <!-- Descripción -->
          <p class="text-sm text-slate-600 dark:text-slate-300 mb-4 flex-1 text-center min-h-[3rem]">
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
                    @click="handleMenuAction('duplicate', a)"
                    class="w-full text-left px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2"
                  >
                    <fluent-icon icon="copy" size="16" />
                    {{ $t('AGENTS_AI.CARD.MENU.DUPLICATE') }}
                  </button>
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
            <div class="flex items-center gap-2" @click.stop>
              <SwitchButton
                :value="isAgentActive(a)"
                @input="toggleAgentStatus(a)"
              />
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
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream

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
=======
=======
>>>>>>> Stashed changes
    
    <!-- Modal para seleccionar agente predeterminado -->
    <woot-modal
      :show.sync="showDefaultAgentModal"
      :on-close="closeDefaultAgentModal"
      size="small"
    >
      <div class="pt-8 pl-8 pr-8 pb-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-lg font-semibold leading-6 text-slate-800 dark:text-slate-50">
            {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.TITLE') }}
          </h2>
          <button
            @click="closeDefaultAgentModal"
            class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
          >
            <fluent-icon icon="dismiss" size="24" />
          </button>
        </div>
        
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-2">
            {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.SUBTITLE') }}
          </h3>
          <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">
            {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.DESCRIPTION') }}
          </p>
        </div>
        
        <div class="mb-6">
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
            {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.SELECT_LABEL') }}
          </label>
          <div class="relative">
            <select
              v-model="selectedDefaultAgentId"
              class="w-full px-4 py-3 pl-10 pr-10 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-woot-500 appearance-none cursor-pointer"
            >
              <option :value="null">{{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.NONE') }}</option>
              <option
                v-for="agent in activeAgents"
                :key="agent.id"
                :value="agent.id"
              >
                {{ agent.name }}
              </option>
            </select>
            <div class="absolute left-3 top-1/2 transform -translate-y-1/2 pointer-events-none">
              <fluent-icon icon="heart" size="20" class="text-woot-500" />
            </div>
            <div class="absolute right-3 top-1/2 transform -translate-y-1/2 pointer-events-none">
              <fluent-icon icon="chevron-down" size="20" class="text-slate-400" />
            </div>
          </div>
        </div>
        
        <div class="flex items-center justify-end gap-2 pt-4 border-t border-slate-200 dark:border-slate-700">
          <button
            @click="closeDefaultAgentModal"
            type="button"
            class="button action-button clear primary"
          >
            <span class="button__content text-left rtl:text-right">
              {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.CANCEL') }}
            </span>
          </button>
          <button
            @click="saveDefaultAgent"
            type="button"
            class="button action-button smooth primary"
          >
            <span class="button__content text-left rtl:text-right">
              {{ $t('AGENTS_AI.MODALS.DEFAULT_AGENT.SAVE') }}
            </span>
          </button>
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        </div>
      </div>
    </woot-modal>
  </div>
</template>
