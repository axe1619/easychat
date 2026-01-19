<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import ModalAgentRag from './components/agentRag/ModalAgentRag.vue';
import ModalAgentCalendar from './components/ModalAgentCalendar.vue';
import ModalAgentCatalog from './components/agentCatalog/ModalAgentCatalog.vue';
import AddInformationRag from './components/agentRag/AddInformationRag.vue';
import TinyEditor from './widgets/TinyEditor.vue';
import Spinner from 'shared/components/Spinner.vue';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import axios from 'axios';
import { frontUrl } from './services/apiAgent';

const SCRIPT_NAME = 'snap-script';

export default {
  components: {
    ModalAgentRag,
    ModalAgentCalendar,
    ModalAgentCatalog,
    AddInformationRag,
    TinyEditor,
    Spinner,
    WootSubmitButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      // Modals for file uploads
      showAgentRag: false,
      showAgentCalendar: false,
      showAgentCatalog: false,
      addNewFile: false,
      
      // Configuration form data
      agentName: '',
      agentDescription: '',
      agentPrompt: '',
      scheduleEnabled: false,
      initAt: '',
      finishAt: '',
      showDescription: false,
      
      // Test agent data
      website: null,
      scriptContent: '',
      injectError: null,
      isRunning: false,
      hasStarted: false,
      cleanupDone: false,
      testTab: 'chat',
      
      // RAG data
      agentRags: [],
      dbCollections: [],
      idDescription: null,
      idDeleteRag: null,
      valueDescription: '',
      deleteNameRag: '',
      isRagUpdating: false,
      isRagDeleting: false,
      
      // Calendar data
      agentCalendars: [],
      outSyncGoogleAccount: false,
      
      // Catalog data
      agentCatalogs: [],
    };
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
      rags: 'rags/getRags',
      ragsUI: 'rags/getUIFlags',
      calendars: 'calendars/getCalendars',
      calendarsUI: 'calendars/getUIFlags',
      catalogs: 'catalogs/getCatalogs',
      catalogsUI: 'catalogs/getUIFlags',
      accountId: 'getCurrentAccountId',
    }),
    agentBot() {
      const botId = this.$route.query.agent;
      if (!botId) return null;
      return this.$store.getters['agentBots/getBot'](botId);
    },
    isButtonDisabled() {
      return (
        this.v$.agentName.$invalid ||
        this.v$.agentPrompt.$invalid
      );
    },
    isUpdating() {
      return (this.uiFlags && this.uiFlags.isUpdating) || false;
    },
    isFetchingRags() {
      return this.ragsUI.isFetching;
    },
    isFetchingCalendars() {
      return this.calendarsUI.isFetching;
    },
    isFetchingCatalogs() {
      return this.catalogsUI.isFetching;
    },
    lastUpdateDays() {
      if (!this.agentBot?.updated_at) return 0;
      try {
        const now = new Date();
        const updated = new Date(this.agentBot.updated_at);
        const diffTime = Math.abs(now - updated);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays || 0;
      } catch (e) {
        return 0;
      }
    },
  },
  watch: {
    agentBot: {
      immediate: true,
      handler(newBot) {
        if (newBot) {
          this.agentName = newBot.name || '';
          this.agentDescription = newBot.description || '';
          this.agentPrompt = newBot.prompt || '';
          this.scheduleEnabled = !!(newBot.init_at || newBot.finish_at);
          this.initAt = newBot.init_at || '';
          this.finishAt = newBot.finish_at || '';
          
          // Initialize test agent
          if (newBot.id && !this.hasStarted) {
            this.initTestAgent(newBot.id);
          }
        }
      },
    },
  },
  async mounted() {
    await this.$store.dispatch('agentBots/get');
    if (this.agentBot?.id) {
      await this.loadAgentData();
    }
    
    // Setup Google auth message listener
    window.addEventListener('message', this.handleGoogleAuthMessage);
    
    // Setup cleanup on unmount
    this._beforeUnload = () => {
      try {
        this.onRemove();
      } catch (e) {}
    };
    window.addEventListener('beforeunload', this._beforeUnload);
  },
  beforeDestroy() {
    window.removeEventListener('beforeunload', this._beforeUnload);
    window.removeEventListener('message', this.handleGoogleAuthMessage);
    this.onRemove();
  },
  methods: {
    async loadAgentData() {
      if (!this.agentBot?.id) return;
      
      // Load RAG data
      try {
        const { data } = await axios.get(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/${this.accountId}-${this.agentBot.id}-`);
        this.dbCollections = data.files || [];
        await this.$store.dispatch('rags/get', { agent_bot_id: this.agentBot.id });
        this.agentRags = this.$store.getters['rags/getRagsByAgentBotId'](Number(this.agentBot.id));
      } catch (e) {
        console.error('Error loading RAG data:', e);
      }
      
      // Load Calendar data
      try {
        await this.$store.dispatch('calendars/get', { agent_bot_id: this.agentBot.id });
        this.agentCalendars = this.$store.getters['calendars/getCalendarsByAgentBotId'](Number(this.agentBot.id));
        this.outSyncGoogleAccount = !this.agentCalendars.some(i => i.platform === 'google');
      } catch (e) {
        console.error('Error loading Calendar data:', e);
      }
      
      // Load Catalog data
      try {
        await this.$store.dispatch('catalogs/get', { agent_bot_id: this.agentBot.id });
        this.agentCatalogs = this.$store.getters['catalogs/getCatalogsByAgentBotId'](Number(this.agentBot.id));
      } catch (e) {
        console.error('Error loading Catalog data:', e);
      }
    },
    
    // Configuration methods
    toggleScheduleEnabled() {
      if (!this.scheduleEnabled) {
        this.initAt = '';
        this.finishAt = '';
      }
      this.scheduleEnabled = !this.scheduleEnabled;
    },
    async saveConfiguration() {
      if (this.isButtonDisabled || this.isUpdating || !this.agentBot || !this.agentBot.id) return;
      
      const data = {
        id: this.agentBot.id,
        name: this.agentName,
        description: this.agentDescription,
        prompt: this.agentPrompt,
        init_at: this.scheduleEnabled ? this.initAt : '',
        finish_at: this.scheduleEnabled ? this.finishAt : '',
      };
      
      try {
        await this.$store.dispatch('agentBots/update', data);
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.UPDATE.SUCCESS'));
        await this.$store.dispatch('agentBots/get');
      } catch (error) {
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.UPDATE.ERROR'));
      }
    },
    cancelChanges() {
      this.$router.push({ name: 'settings_agents_ai' });
    },
    
    // Test Agent methods
    async initTestAgent(agentBotId) {
      if (!agentBotId || this.hasStarted) return;
      
      this.isRunning = true;
      this.injectError = null;
      
      try {
        if (!this.website?.id) {
          const website = await this.$store.dispatch('inboxes/createWebsiteChannel', {
            name: 'Agente de Prueba',
            greeting_enabled: false,
            greeting_message: 'Hi there!',
            enable_email_collect: false,
            mode: 'sandbox',
            channel: {
              type: 'web_widget',
              website_url: 'http://localhost:3000/',
              widget_color: '#009CE0',
              welcome_title: 'Agente de Prueba!',
              welcome_tagline: 'Bienvenido al entorno de prueba de Agente de Prueba',
            },
          });
          this.website = website || null;
          this.scriptContent = website?.web_widget_script || '';
        } else {
          this.scriptContent = this.website?.web_widget_script || this.scriptContent;
        }
        
        if (this.website?.id && agentBotId) {
          await this.$store.dispatch('agentBots/setAgentBotInbox', {
            inboxId: this.website.id,
            botId: agentBotId,
          });
          this.injectWidgetScript(this.scriptContent);
          this.hasStarted = true;
        }
      } catch (e) {
        console.error('initTestAgent error:', e);
        this.injectError = e?.message || 'Unexpected error';
      } finally {
        this.isRunning = false;
      }
    },
    injectWidgetScript(rawScript) {
      this.removeScript();
      if (!rawScript) return;
      
      const decoded = rawScript
        .replace(/\\u003c/g, '<')
        .replace(/\\u003e/g, '>');
      const match = decoded.match(/<script[^>]*>([\s\S]*?)<\/script>/i);
      let code = match ? match[1] : decoded;
      
      code = code.replace(
        /var BASE_URL\s*=\s*["']https:\/\/www\.easycontact\.top["'];/,
        'var BASE_URL="http://localhost:3000";'
      );
      
      const blob = new Blob([code], { type: 'text/javascript' });
      const src = URL.createObjectURL(blob);
      
      const script = document.createElement('script');
      script.setAttribute('name', SCRIPT_NAME);
      script.type = 'text/javascript';
      script.src = src;
      script.async = true;
      
      script.onload = () => {
        URL.revokeObjectURL(src);
        const observer = new MutationObserver(() => {
          const bubble = document.querySelector('.woot-widget-bubble.woot-elements--right');
          if (bubble) {
            bubble.click();
            observer.disconnect();
          }
        });
        observer.observe(document.body, { childList: true, subtree: true });
      };
      
      script.onerror = () => {
        URL.revokeObjectURL(src);
        console.error('Failed to load injected script');
      };
      
      document.head.appendChild(script);
    },
    removeScript() {
      document.querySelectorAll(`script[name="${SCRIPT_NAME}"]`).forEach(el => el.remove());
      document.querySelectorAll('iframe[src*="easycontact.top"], iframe[src*="localhost:3000"], iframe[id^="woot-"], iframe[name^="woot-"]').forEach(el => el.remove());
      document.querySelectorAll('[class*="woot-widget-holder"]').forEach(el => el.remove());
      document.querySelectorAll('[class*="woot--bubble-holder"]').forEach(el => el.remove());
    },
    async onRemove() {
      if (this.cleanupDone) return;
      this.cleanupDone = true;
      
      try {
        this.removeScript();
      } catch (e) {
        console.error('removeScript error:', e);
      }
      
      try {
        if (this.website?.id) {
          await this.$store.dispatch('inboxes/delete', this.website.id);
          this.website = null;
        }
      } catch (e) {
        console.error('deleteInbox error:', e);
      }
    },
    resetChat() {
      this.onRemove();
      this.hasStarted = false;
      this.cleanupDone = false;
      if (this.agentBot?.id) {
        this.initTestAgent(this.agentBot.id);
      }
    },
    
    // RAG methods
    toggleAddNewFile() {
      this.addNewFile = !this.addNewFile;
    },
    async refreshRags() {
      if (!this.agentBot?.id) return;
      await this.$store.dispatch('rags/get', { agent_bot_id: this.agentBot.id });
      this.agentRags = this.$store.getters['rags/getRagsByAgentBotId'](Number(this.agentBot.id));
      try {
        const { data } = await axios.get(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/${this.accountId}-${this.agentBot.id}-`);
        this.dbCollections = data.files || [];
      } catch (e) {
        console.error('Error refreshing RAG collections:', e);
      }
    },
    formatDate(timestamp) {
      const date = new Date(timestamp);
      return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      });
    },
    activeEditDescription(id, value) {
      this.idDescription = id;
      this.valueDescription = value;
    },
    desactiveEditDescription() {
      this.idDescription = null;
      this.valueDescription = '';
    },
    activeDeleteRag(id, name) {
      this.idDeleteRag = id;
      this.deleteNameRag = name;
    },
    desactiveDeleteRag() {
      this.idDeleteRag = null;
      this.deleteNameRag = '';
    },
    async updateDescriptionRag() {
      const data = {
        id: this.idDescription,
        description: this.valueDescription,
      };
      await this.$store.dispatch('rags/update', data);
      useAlert(this.$t('AGENTS_AI.ALERT.RAG.UPDATE.SUCCESS'));
      this.desactiveEditDescription();
      await this.refreshRags();
    },
    async deleteRag() {
      if (!this.agentBot?.id) return;
      const id = this.idDeleteRag;
      const name = `${this.accountId}-${this.agentBot.id}-${this.deleteNameRag}`;
      
      try {
        this.isRagDeleting = true;
        await axios.delete(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/delete-collection/${name}`);
        await this.$store.dispatch('rags/delete', id);
        useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.SUCCESS'));
      } catch (err) {
        if (err?.response?.status === 404) {
          await this.$store.dispatch('rags/delete', id);
          useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.SUCCESS'));
        } else {
          useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.ERROR'));
        }
      } finally {
        this.isRagDeleting = false;
        this.desactiveDeleteRag();
        await this.refreshRags();
      }
    },
    
    // Calendar methods
    loginWithGoogle() {
      window.open(`${frontUrl}/api/google`, 'googleLoginPopup', 'width=500,height=600');
    },
    handleGoogleAuthMessage(event) {
      let origin = process.env.FRONTEND_URL.replace(/^https?:\/\//, '').replace(/^www\./, '');
      if (!event.origin.includes(origin)) return;
      
      const { access_token, refresh_token, id_token, user } = event.data;
      if (!access_token) return;
      
      const data = {
        platform: 'google',
        id_token: id_token,
        access_token: access_token,
        refresh_token: refresh_token,
        email: user.email,
        user_name: user.user_name,
        picture: user.picture,
      };
      
      this.createCalendar(data);
    },
    async createCalendar(data) {
      if (!this.agentBot?.id) return;
      const newData = {
        agent_bot_id: this.agentBot.id,
        account_id: this.accountId,
        ...data
      };
      await this.$store.dispatch('calendars/create', newData);
      await this.loadAgentData();
    },
    async deleteCalendar(id) {
      await this.$store.dispatch('calendars/delete', id);
      await this.loadAgentData();
    },
    
    // Catalog methods
    exportToCSV() {
      if (!this.agentCatalogs || !this.agentCatalogs.length) {
        console.error('No hay datos para exportar');
        return;
      }
      
      const headers = ['codigo', 'nombre', 'descripcion', 'descripcion_larga', 'categoria', 'subcategoria', 'precio', 'moneda', 'unidad_medida', 'presentacion', 'stock_disponible', 'stock_minimo', 'descuento', 'precio_oferta', 'impuesto', 'estado', 'marca', 'proveedor', 'codigo_barras', 'imagen_url', 'galeria_imagenes', 'ficha_tecnica_url', 'manual_url', 'video_url', 'pais_origen', 'garantia', 'fecha_creacion', 'fecha_actualizacion', 'etiquetas', 'politicas_envio', 'politicas_devolucion', 'variantes', 'relacionados', 'ratings'];
      const csvRows = [];
      
      csvRows.push(headers.join(','));
      
      for (const row of this.agentCatalogs) {
        const values = headers.map(h => {
          const val = row[h] ?? '';
          return `"${String(val).replace(/"/g, '""')}"`;
        });
        csvRows.push(values.join(','));
      }
      
      const csvString = csvRows.join('\n');
      const csvWithBOM = '\uFEFF' + csvString;
      
      const date = new Date().toLocaleDateString('es-BO', {
        timeZone: 'America/La_Paz',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      }).replace(/\//g, '');
      
      const blob = new Blob([csvWithBOM], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.setAttribute('download', `catalog-${date}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    },
    
    // Modal handlers
    hideAgentRag() {
      this.showAgentRag = false;
      this.refreshRags();
    },
    hideAgentCalendar() {
      this.showAgentCalendar = false;
      this.loadAgentData();
    },
    hideAgentCatalog() {
      this.showAgentCatalog = false;
      this.loadAgentData();
    },
  },
  validations: {
    agentName: { required },
    agentPrompt: { required },
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 overflow-auto bg-slate-50 dark:bg-slate-900">
    <!-- Loading State -->
    <div v-if="!agentBot" class="flex items-center justify-center min-h-screen">
      <Spinner />
    </div>

    <!-- Main Content -->
    <div v-else>
      <!-- Header with Save/Cancel -->
      <div class="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 px-6 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <button @click="cancelChanges" class="text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white">
              <fluent-icon icon="arrow-left" size="20" />
            </button>
            <div>
              <h1 class="text-xl font-bold text-slate-900 dark:text-white">
                {{ $t('AGENTS_AI.CAPABILITIES.HEADER.EDIT_TITLE', { agentName: (agentBot && agentBot.name) || '' }) }}
              </h1>
              <div class="flex items-center gap-3 mt-1">
                <span v-if="agentBot && agentBot.status === 'active'" class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  {{ $t('AGENTS_AI.CAPABILITIES.HEADER.ACTIVE') }}
                </span>
                <span class="text-sm text-slate-500 dark:text-slate-400">
                  {{ $t('AGENTS_AI.CAPABILITIES.HEADER.LAST_UPDATE', { days: lastUpdateDays }) }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <button @click="cancelChanges" class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-md hover:bg-slate-50 dark:hover:bg-slate-600">
              {{ $t('AGENTS_AI.CAPABILITIES.HEADER.CANCEL') }}
            </button>
            <woot-button
              :disabled="isButtonDisabled || isUpdating"
              :loading="isUpdating"
              @click="saveConfiguration"
              color-scheme="primary"
            >
              {{ $t('AGENTS_AI.CAPABILITIES.HEADER.SAVE') }}
            </woot-button>
          </div>
        </div>
      </div>

    <!-- Main Content -->
    <div class="p-6 space-y-6">
      <!-- Configuration and Test Agent - Two Column Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Left Column: Configuration -->
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 space-y-6">
          <div>
            <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-2">
              {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.TITLE') }}
            </h2>
            <p class="text-sm text-slate-600 dark:text-slate-400">
              {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.DESCRIPTION') }}
            </p>
          </div>

          <!-- Emoji and Name -->
          <div class="flex items-start gap-3">
            <div class="flex-shrink-0">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.EMOJI_LABEL') }}
              </label>
              <div class="w-12 h-12 rounded border border-slate-300 dark:border-slate-600 flex items-center justify-center bg-slate-50 dark:bg-slate-700">
                <span class="text-2xl">💜</span>
              </div>
            </div>
            <div class="flex-1">
              <woot-input
                v-model="agentName"
                :label="$t('AGENTS_AI.CAPABILITIES.CONFIGURATION.NAME_LABEL')"
                type="text"
                :class="{ error: v$.agentName.$error }"
                :error="v$.agentName.$error ? $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.NAME.ERROR') : ''"
                :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.NAME.PLACEHOLDER')"
                @blur="v$.agentName.$touch"
              />
            </div>
          </div>

          <!-- Show Description Toggle -->
          <button
            @click="showDescription = !showDescription"
            class="text-sm text-woot-500 hover:text-woot-600 dark:text-woot-400 dark:hover:text-woot-300"
          >
            {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.SHOW_DESCRIPTION') }}
          </button>

          <!-- Description (if shown) -->
          <div v-if="showDescription">
            <woot-input
              v-model="agentDescription"
              :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.LABEL')"
              type="text"
              :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.PLACEHOLDER')"
            />
          </div>

          <!-- Instructions Section -->
          <div class="space-y-4">
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white mb-2">
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.TITLE') }}
              </h3>
              <p class="text-sm text-slate-600 dark:text-slate-400">
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.DESCRIPTION') }}
              </p>
            </div>

            <div>
              <TinyEditor v-model="agentPrompt" :height="300" />
              <p v-if="v$.agentPrompt.$error" class="mt-1 text-sm text-red-600">
                {{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.PROMPT.ERROR') }}
              </p>
            </div>

            <!-- Prompt Actions -->
            <div class="flex items-center gap-3 flex-wrap">
              <woot-button
                variant="smooth"
                color-scheme="secondary"
                size="small"
                icon="add"
              >
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.ADD_TEMPLATES') }}
              </woot-button>
              <woot-button
                variant="smooth"
                color-scheme="primary"
                size="small"
                icon="graph"
              >
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.OPTIMIZE') }}
              </woot-button>
            </div>

            <a href="#" class="inline-flex items-center gap-1 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300">
              <fluent-icon icon="book" size="16" />
              {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.LEARN_TO_WRITE') }}
            </a>
          </div>

          <!-- Schedule -->
          <div class="flex items-center">
            <input
              id="scheduleEnabledId"
              v-model="scheduleEnabled"
              type="checkbox"
              @change="toggleScheduleEnabled"
              class="me-2"
            />
            <label for="scheduleEnabledId" class="text-sm text-slate-700 dark:text-slate-300">
              {{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.LABEL') }}
            </label>
          </div>

          <div v-if="scheduleEnabled" class="grid grid-cols-2 gap-4">
            <woot-input
              v-model="initAt"
              :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.INIT')"
              type="time"
            />
            <woot-input
              v-model="finishAt"
              :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.FINISH')"
              type="time"
            />
          </div>
        </div>

        <!-- Right Column: Test Agent -->
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 flex flex-col">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white">
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.TITLE') }}
            </h2>
            <div class="flex items-center gap-2">
              <fluent-icon icon="call" size="20" class="text-slate-500 dark:text-slate-400" />
              <woot-button
                variant="smooth"
                color-scheme="secondary"
                size="small"
                @click="resetChat"
              >
                {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.RESET_CHAT') }}
              </woot-button>
            </div>
          </div>

          <!-- Tabs -->
          <div class="flex border-b border-slate-200 dark:border-slate-700 mb-4">
            <button
              @click="testTab = 'chat'"
              :class="[
                'px-4 py-2 text-sm font-medium border-b-2 transition-colors',
                testTab === 'chat'
                  ? 'border-woot-500 text-woot-500'
                  : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300'
              ]"
            >
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.TAB_CHAT') }}
            </button>
            <button
              @click="testTab = 'contact'"
              :class="[
                'px-4 py-2 text-sm font-medium border-b-2 transition-colors',
                testTab === 'contact'
                  ? 'border-woot-500 text-woot-500'
                  : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300'
              ]"
            >
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.TAB_CONTACT_FIELDS') }}
            </button>
          </div>

          <!-- Chat Content -->
          <div v-if="testTab === 'chat'" class="flex-1 flex flex-col min-h-[400px]">
            <div v-if="!hasStarted" class="flex-1 flex flex-col items-center justify-center text-center p-8">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-2">
                {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.EMPTY_STATE.TITLE') }}
              </h3>
              <p class="text-sm text-slate-600 dark:text-slate-400 max-w-md">
                {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.EMPTY_STATE.DESCRIPTION') }}
              </p>
            </div>
            <div v-else class="flex-1 flex flex-col">
              <!-- Chat messages area would go here -->
              <div class="flex-1 p-4 overflow-y-auto">
                <p class="text-sm text-slate-500 dark:text-slate-400 text-center">
                  {{ $t('AGENTS_AI.MODALS.SANDBOX.CHAT_EMPTY') }}
                </p>
              </div>
              <!-- Message Input -->
              <div class="border-t border-slate-200 dark:border-slate-700 p-4">
                <div class="flex items-center gap-2">
                  <input
                    type="text"
                    :placeholder="$t('AGENTS_AI.CAPABILITIES.TEST_AGENT.PLACEHOLDER')"
                    class="flex-1 px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-woot-500"
                  />
                  <button class="p-2 text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300">
                    <fluent-icon icon="send" size="20" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Contact Fields Content -->
          <div v-else class="flex-1 p-4">
            <p class="text-sm text-slate-500 dark:text-slate-400">
              Contact fields content goes here
            </p>
          </div>
        </div>
      </div>

      <!-- Actions Section -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 space-y-6">
        <div>
          <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-2">
            {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.TITLE') }}
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.DESCRIPTION') }}
          </p>
        </div>

        <!-- Knowledge Sources -->
        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-base font-semibold text-slate-900 dark:text-white mb-4">
            {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.TITLE') }}
          </h3>

          <!-- Empty State -->
          <div v-if="!agentRags || agentRags.length === 0" class="space-y-4">
            <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 flex items-start gap-3">
              <fluent-icon icon="warning" size="20" class="text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
              <p class="text-sm text-amber-800 dark:text-amber-200">
                {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_ALERT') }}
              </p>
            </div>
            <div class="text-center py-8">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-700 mb-4">
                <fluent-icon icon="book-add" size="32" class="text-slate-500 dark:text-slate-400" />
              </div>
              <h4 class="text-base font-semibold text-slate-900 dark:text-white mb-2">
                {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_TITLE') }}
              </h4>
              <p class="text-sm text-slate-600 dark:text-slate-400 mb-4 max-w-md mx-auto">
                {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_DESCRIPTION') }}
              </p>
              <woot-button
                color-scheme="primary"
                icon="add"
                @click="showAgentRag = true"
              >
                {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.ADD_BUTTON') }}
              </woot-button>
            </div>
          </div>

          <!-- RAG List -->
          <div v-else class="space-y-4">
            <div class="flex justify-end">
              <woot-button
                variant="smooth"
                color-scheme="primary"
                icon="add"
                size="small"
                @click="showAgentRag = true"
              >
                {{ $t('AGENTS_AI.CARDS.RAG.ADD') }}
              </woot-button>
            </div>
            <div class="divide-y divide-slate-200 dark:divide-slate-700">
              <div v-for="item in agentRags" :key="item.id" class="py-4 flex items-start justify-between gap-4">
                <div class="flex-1">
                  <p class="font-semibold text-slate-900 dark:text-white mb-1">
                    {{ item.collection_name }} - {{ formatDate(item.created_at) }}
                  </p>
                  <p class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                    {{ $t('AGENTS_AI.CARDS.RAG.FORM.LABEL_DESCRIPTION') }}:
                  </p>
                  <textarea
                    v-if="item.id === idDescription"
                    v-model="valueDescription"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-white text-sm"
                    :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')"
                  />
                  <p v-else class="text-sm text-slate-600 dark:text-slate-400">
                    {{ item.description || '-' }}
                  </p>
                </div>
                <div class="flex items-center gap-2">
                  <div v-if="isRagUpdating || isRagDeleting" class="p-2">
                    <Spinner />
                  </div>
                  <div v-else-if="item.id === idDescription" class="flex gap-2">
                    <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark" @click="updateDescriptionRag" />
                    <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss" @click="desactiveEditDescription" />
                  </div>
                  <div v-else-if="item.id === idDeleteRag" class="flex gap-2">
                    <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark" @click="deleteRag" />
                    <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss" @click="desactiveDeleteRag" />
                  </div>
                  <div v-else class="flex gap-2">
                    <woot-button
                      v-if="dbCollections.includes(item.collection_name)"
                      size="tiny"
                      variant="smooth"
                      color-scheme="primary"
                      icon="edit"
                      @click="activeEditDescription(item.id, item.description)"
                    />
                    <span v-else class="inline-flex items-center p-2 bg-yellow-100 dark:bg-yellow-900/30 rounded">
                      <fluent-icon icon="warning" size="16" class="text-yellow-600 dark:text-yellow-400" />
                    </span>
                    <woot-button
                      size="tiny"
                      variant="smooth"
                      color-scheme="alert"
                      icon="delete"
                      @click="activeDeleteRag(item.id, item.collection_name)"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Calendar -->
        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-slate-900 dark:text-white">
              {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.CALENDAR.TITLE') }}
            </h3>
            <woot-button
              v-if="outSyncGoogleAccount"
              variant="smooth"
              color-scheme="primary"
              icon="add-circle"
              size="small"
              @click="showAgentCalendar = true"
            >
              {{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.ADD_GOOGLE_ACOUNT') }}
            </woot-button>
          </div>

          <div v-if="isFetchingCalendars" class="flex justify-center py-8">
            <Spinner />
          </div>
          <div v-else-if="agentCalendars && agentCalendars.length > 0" class="space-y-3">
            <div v-for="calendar in agentCalendars" :key="calendar.id" class="flex items-center justify-between p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
              <div class="flex items-center gap-4">
                <img :src="calendar.picture" class="w-12 h-12 rounded-full object-cover" />
                <div>
                  <p class="font-semibold text-slate-900 dark:text-white">{{ calendar.user_name }}</p>
                  <p class="text-sm text-slate-600 dark:text-slate-400">{{ calendar.email }}</p>
                  <div v-if="calendar.platform === 'google'" class="mt-2 inline-block px-2 py-1 bg-slate-100 dark:bg-slate-700 rounded">
                    <img src="/assets/images/dashboard/agents-ai/google.png" alt="Google" class="h-4" />
                  </div>
                </div>
              </div>
              <woot-button
                variant="smooth"
                color-scheme="alert"
                size="small"
                icon="delete"
                @click="deleteCalendar(calendar.id)"
              >
                {{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.DELETE') }}
              </woot-button>
            </div>
          </div>
          <div v-else class="text-center py-8 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('AGENTS_AI.CARDS.CALENDAR.DESCRIPTION') }}
          </div>
        </div>

        <!-- Catalog -->
        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-semibold text-slate-900 dark:text-white">
              {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.CATALOG.TITLE') }}
            </h3>
            <div class="flex gap-2">
              <woot-button
                variant="smooth"
                color-scheme="info"
                icon="upload"
                size="small"
                @click="showAgentCatalog = true"
              >
                {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}
              </woot-button>
              <woot-button
                variant="smooth"
                color-scheme="info"
                icon="download"
                size="small"
                @click="exportToCSV"
                :disabled="!agentCatalogs || agentCatalogs.length === 0"
              >
                {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_EXPORT') }}
              </woot-button>
            </div>
          </div>

          <div v-if="isFetchingCatalogs" class="flex justify-center py-8">
            <Spinner />
          </div>
          <div v-else-if="agentCatalogs && agentCatalogs.length > 0" class="overflow-x-auto">
            <table class="min-w-full border-collapse">
              <thead class="bg-slate-100 dark:bg-slate-700">
                <tr>
                  <th v-for="(h, i) in ['codigo', 'nombre', 'descripcion', 'precio', 'stock_disponible']" :key="i" class="px-4 py-2 text-left text-sm font-semibold text-slate-900 dark:text-white border-b border-slate-200 dark:border-slate-600">
                    {{ h }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(catalog, idx) in agentCatalogs.slice(0, 5)" :key="idx" class="border-b border-slate-200 dark:border-slate-700">
                  <td v-for="(h, ci) in ['codigo', 'nombre', 'descripcion', 'precio', 'stock_disponible']" :key="ci" class="px-4 py-2 text-sm text-slate-700 dark:text-slate-300">
                    {{ catalog[h] }}
                  </td>
                </tr>
              </tbody>
            </table>
            <p v-if="agentCatalogs.length > 5" class="text-sm text-slate-500 dark:text-slate-400 mt-2 text-center">
              {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}: {{ agentCatalogs.length }} {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.PROGRESS') }}
            </p>
          </div>
          <div v-else class="text-center py-8 text-sm text-slate-500 dark:text-slate-400">
            {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.DESCRIPTION_A') }}
          </div>
        </div>
      </div>
    </div>

      <!-- Modals for file uploads -->
      <woot-modal :show.sync="showAgentRag" :on-close="hideAgentRag">
        <ModalAgentRag :on-close="hideAgentRag" :botId="agentBot && agentBot.id" :accountId="agentBot && agentBot.account_id" />
      </woot-modal>

      <woot-modal :show.sync="showAgentCalendar" :on-close="hideAgentCalendar">
        <ModalAgentCalendar :on-close="hideAgentCalendar" :botId="agentBot && agentBot.id" :accountId="agentBot && agentBot.account_id" />
      </woot-modal>

      <woot-modal :show.sync="showAgentCatalog" :on-close="hideAgentCatalog">
        <ModalAgentCatalog :on-close="hideAgentCatalog" :botId="agentBot && agentBot.id" :accountId="agentBot && agentBot.account_id" />
      </woot-modal>
    </div>
  </div>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>
