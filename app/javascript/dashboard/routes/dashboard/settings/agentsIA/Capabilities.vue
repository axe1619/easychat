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
const TEST_INBOX_NAME = 'Agente de Prueba';

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
      // Always show description
      // showTemplatesDropdown removed (no prompt templates in capabilities)
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      avatarUrl: null,
      avatarFile: null,
      // Cancel confirmation
      showCancelConfirm: false,
      // promptTemplates removed
      
      // Test agent data
      website: null,
      scriptContent: '',
      injectError: null,
      isRunning: false,
      hasStarted: false,
      cleanupDone: false,
      
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
    updatedLabel() {
      if (!this.agentBot?.updated_at) return '';
      try {
        const now = new Date();
        const updated = new Date(this.agentBot.updated_at);
        const diffMs = now - updated;
        const diffSec = Math.round(diffMs / 1000);
        const diffMin = Math.round(diffSec / 60);
        const diffHours = Math.round(diffMin / 60);

        const locale = (this.$i18n && this.$i18n.locale) || 'es';

        // Usar RelativeTimeFormat solo si está disponible en el navegador
        if (typeof Intl !== 'undefined' && typeof Intl.RelativeTimeFormat !== 'undefined') {
          const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

          if (Math.abs(diffMin) < 60) {
            return rtf.format(-Math.round(diffMin), 'minute');
          }
          if (Math.abs(diffHours) < 24) {
            return rtf.format(-Math.round(diffHours), 'hour');
          }
        }

        // Fallback: fecha y hora formateadas
        const date = new Date(this.agentBot.updated_at);
        return date.toLocaleDateString(locale, {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit'
        });
      } catch (e) {
        return '';
      }
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
    formattedUpdatedAt() {
      if (!this.agentBot?.updated_at) return '';
      try {
        const date = new Date(this.agentBot.updated_at);
        return date.toLocaleDateString('es-ES', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit'
        });
      } catch (e) {
        return '';
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
          this.avatarUrl = newBot.avatar_url || null;
          this.avatarFile = null;
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
  beforeRouteLeave(to, from, next) {
    this.onRemove();
    next();
  },
  beforeDestroy() {
    window.removeEventListener('beforeunload', this._beforeUnload);
    window.removeEventListener('message', this.handleGoogleAuthMessage);
    if (this.avatarUrl && this.avatarUrl.startsWith('blob:')) {
      URL.revokeObjectURL(this.avatarUrl);
    }
    this.onRemove();
  },
  methods: {
    mountTestAgentWidget() {
      const container = this.$refs.testAgentChatContainer;
      if (!container) return;

      const holder =
        document.querySelector('.woot-widget-holder') ||
        Array.from(document.querySelectorAll('[class*="woot-widget-holder"]'))[0];

      if (holder && !container.contains(holder)) {
        container.innerHTML = '';
        container.appendChild(holder);
      }

      if (window.$chatwoot && typeof window.$chatwoot.toggle === 'function') {
        try {
          window.$chatwoot.toggle();
        } catch (e) {
          // ignore toggle errors
        }
      }
    },
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
      if (this.avatarFile instanceof File) {
        data.avatar = this.avatarFile;
      }

      try {
        await this.$store.dispatch('agentBots/update', data);
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.UPDATE.SUCCESS'));
        await this.$store.dispatch('agentBots/get');
      } catch (error) {
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.UPDATE.ERROR'));
      }
    },
    triggerAvatarUpload() {
      this.$refs.avatarInput?.click();
    },
    handleAvatarUpload(event) {
      const file = event.target.files?.[0];
      if (!file) return;

      if (!file.type.startsWith('image/')) {
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_INVALID_TYPE'));
        return;
      }

      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_SIZE_LIMIT'));
        return;
      }

      if (this.avatarUrl && this.avatarUrl.startsWith('blob:')) {
        URL.revokeObjectURL(this.avatarUrl);
      }
      this.avatarFile = file;
      this.avatarUrl = URL.createObjectURL(file);
      useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_UPLOAD_SUCCESS'));
      if (event.target) event.target.value = '';
    },
    cancelChanges() {
      // If there are unsaved changes, show confirm modal
      const nameChanged = this.agentName !== (this.agentBot && this.agentBot.name) || false;
      const descChanged = this.agentDescription !== (this.agentBot && this.agentBot.description) || false;
      const promptChanged = this.agentPrompt !== (this.agentBot && this.agentBot.prompt) || false;
      if (nameChanged || descChanged || promptChanged || this.avatarFile) {
        this.showCancelConfirm = true;
        return;
      }
      this.$router.push({ name: 'settings_agents_ia' });
    },
    hideCancelConfirm() {
      this.showCancelConfirm = false;
    },
    confirmExitWithoutSaving() {
      this.showCancelConfirm = false;
      this.$router.push({ name: 'settings_agents_ia' });
    },
    
    // Test Agent: solo al hacer clic en "Iniciar prueba". Reutilizar inbox "Agente de Prueba".
    async initTestAgent(agentBotId) {
      if (!agentBotId || this.hasStarted) return;

      this.isRunning = true;
      this.injectError = null;

      try {
        await this.$store.dispatch('inboxes/get');
        if (!this.website?.id) {
          const websiteInboxes = this.$store.getters['inboxes/getWebsiteInboxes'] || [];
          const existing = websiteInboxes.find(
            inbox => inbox.name && inbox.name.trim() === TEST_INBOX_NAME
          );
          if (existing) {
            this.website = existing;
            this.scriptContent = existing.web_widget_script || '';
          } else {
            const website = await this.$store.dispatch('inboxes/createWebsiteChannel', {
              name: TEST_INBOX_NAME,
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
          }
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
        // Dar tiempo a que el widget se monte y luego moverlo al contenedor fijo
        setTimeout(() => {
          this.mountTestAgentWidget();
        }, 1000);
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
      // No eliminar el inbox de prueba: se reutiliza en futuras visitas a Capabilities
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
              <h1 class="text-lg font-bold text-slate-900 dark:text-white mb-1">
                {{ $t('AGENTS_AI.CAPABILITIES.HEADER.EDIT_TITLE', { agentName: (agentBot && agentBot.name) || '' }) }}
              </h1>
              <div class="flex items-center gap-3 mt-1">
                <span v-if="agentBot && agentBot.status === 'active'" class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  {{ $t('AGENTS_AI.CAPABILITIES.HEADER.ACTIVE') }}
                </span>
                <span class="text-sm text-slate-500 dark:text-slate-400">
                  {{ updatedLabel ? $t('AGENTS_AI.CAPABILITIES.HEADER.LAST_UPDATE_DATE', { date: updatedLabel }) : $t('AGENTS_AI.CAPABILITIES.HEADER.LAST_UPDATE', { days: lastUpdateDays }) }}
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

          <!-- Imagen (avatar) y Nombre -->
          <div class="flex items-start gap-3">
            <div class="flex-shrink-0">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.IMAGE_LABEL') }}
              </label>
              <input
                ref="avatarInput"
                type="file"
                accept="image/*"
                class="hidden"
                @change="handleAvatarUpload"
              />
              <div
                @click="triggerAvatarUpload"
                class="w-20 h-20 rounded border border-slate-300 dark:border-slate-600 flex items-center justify-center bg-slate-50 dark:bg-slate-700 overflow-hidden cursor-pointer hover:border-woot-500 dark:hover:border-woot-500 transition-colors relative group"
              >
                <img
                  :src="avatarUrl || (agentBot && agentBot.avatar_url) || avatarDefault"
                  :alt="agentName"
                  class="w-full h-full object-cover"
                />
                <div
                  class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 flex items-center justify-center transition-opacity"
                >
                  <fluent-icon
                    icon="camera"
                    size="24"
                    class="text-white opacity-0 group-hover:opacity-100 transition-opacity"
                  />
                </div>
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

          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">{{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.LABEL') }}</label>
          <textarea
            v-model="agentDescription"
            rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.PLACEHOLDER')"
          />

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
  
            </div>
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
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 flex flex-col lg:sticky lg:top-24 lg:h-[calc(100vh-8rem)]">
          <div class="flex items-center justify-between mb-4">
          </div>

          <div v-if="!hasStarted" class="flex-1 flex flex-col items-center justify-center text-center p-8">
            <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.EMPTY_STATE.TITLE') }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-400 max-w-md mb-4">
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.EMPTY_STATE.DESCRIPTION') }}
            </p>
            <woot-button
              variant="smooth"
              color-scheme="primary"
              size="small"
              :loading="isRunning"
              :disabled="isRunning"
              @click="initTestAgent(agentBot && agentBot.id)"
            >
              {{ $t('AGENTS_AI.CAPABILITIES.TEST_AGENT.START_BUTTON') }}
            </woot-button>
          </div>
          <div v-else class="flex-1 p-0">
            <div class="h-full flex flex-col">
              <div
                ref="testAgentChatContainer"
                class="mt-2 flex-1 border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden bg-slate-50 dark:bg-slate-900"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Actions Section -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Left Column: Actions (align with Configuration) -->
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
                  <fluent-icon icon="folder" size="32" class="text-slate-500 dark:text-slate-400" />
                </div>
                <h4 class="text-base font-semibold text-slate-900 dark:text-white mb-2">
                  {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_TITLE') }}
                </h4>
                <p class="text-sm text-slate-600 dark:text-slate-400 mb-4 max-w-md mx-auto">
                  {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_DESCRIPTION') }}
                </p>
                <woot-button
                  color-scheme="primary"
                  @click="showAgentRag = true"
                >
                  {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.ADD_BUTTON') }}
                </woot-button>
              </div>
            </div>

            <!-- RAG List -->
            <div v-else>
              <div class="flex justify-end mb-4">
                <woot-button
                  variant="smooth"
                  color-scheme="primary"
                  size="small"
                  @click="showAgentRag = true"
                >
                  {{ $t('AGENTS_AI.CARDS.RAG.ADD') }}
                </woot-button>
              </div>
              <div class="px-0 pb-0">
                <table class="divide-y divide-slate-75 dark:divide-slate-700 w-full">
                  <thead class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300">
                    <tr>
                      <th class="text-center py-3">ARCHIVO</th>
                      <th class="text-center py-3">ACCION</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300">
                    <tr v-if="isRagUpdating || isRagDeleting">
                      <td colspan="2" class="py-4">
                        <div class="flex justify-center items-center">
                          <Spinner />
                        </div>
                      </td>
                    </tr>
                    <tr v-else v-for="item in agentRags" :key="item.id">
                      <td class="py-2 text-center">
                        <p class="text-center font-bold">
                          {{ item.collection_name }} - {{ formatDate(item.created_at) }}
                        </p>
                        <p class="font-semibold mt-2">
                          {{ $t('AGENTS_AI.CARDS.RAG.FORM.LABEL_DESCRIPTION') }}
                        </p>
                        <textarea
                          v-if="item.id === idDescription"
                          v-model="valueDescription"
                          class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-white text-sm"
                          :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')"
                        />
                        <span v-else class="text-sm text-slate-600 dark:text-slate-400">
                          {{ item.description || '-' }}
                        </span>
                      </td>
                      <td class="py-4 text-center">
                        <div v-if="item.id === idDescription" class="flex justify-evenly items-center">
                          <woot-button
                            size="tiny"
                            variant="smooth"
                            color-scheme="success"
                            icon="checkmark"
                            @click="updateDescriptionRag"
                          />
                          <woot-button
                            size="tiny"
                            variant="smooth"
                            color-scheme="alert"
                            icon="dismiss"
                            @click="desactiveEditDescription"
                          />
                        </div>
                        <div v-else-if="item.id === idDeleteRag" class="flex justify-evenly items-center">
                          <woot-button
                            size="tiny"
                            variant="smooth"
                            color-scheme="success"
                            icon="checkmark"
                            @click="deleteRag"
                          />
                          <woot-button
                            size="tiny"
                            variant="smooth"
                            color-scheme="alert"
                            icon="dismiss"
                            @click="desactiveDeleteRag"
                          />
                        </div>
                        <div v-else class="flex justify-evenly items-center">
                          <woot-button
                            v-if="dbCollections.includes(item.collection_name)"
                            size="tiny"
                            variant="smooth"
                            color-scheme="primary"
                            icon="edit"
                            @click="activeEditDescription(item.id, item.description)"
                          />
                          <span
                            v-else
                            class="inline-flex items-center p-2 bg-yellow-100 dark:bg-yellow-900/30 rounded"
                          >
                            <fluent-icon
                              icon="warning"
                              size="16"
                              class="text-yellow-600 dark:text-yellow-400"
                            />
                          </span>
                          <woot-button
                            size="tiny"
                            variant="smooth"
                            color-scheme="alert"
                            icon="delete"
                            @click="activeDeleteRag(item.id, item.collection_name)"
                          />
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
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
        <div></div>
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

      <!-- Cancel confirmation modal -->
      <woot-modal :show.sync="showCancelConfirm" :on-close="hideCancelConfirm" size="small">
        <div class="pt-8 pl-8 pr-8 pb-4">
          <h2 class="text-lg font-semibold leading-6 text-slate-800 dark:text-slate-50">{{ $t('AGENTS_AI.MODALS.CREATE_CANCEL.TITLE') }}</h2>
          <p class="mt-4 text-sm text-slate-600 dark:text-slate-300">{{ $t('AGENTS_AI.MODALS.CREATE_CANCEL.BODY') }}</p>
          <div class="flex items-center justify-end gap-2 pt-6">
            <button @click="showCancelConfirm = false" type="button" class="button action-button clear primary">{{ $t('AGENTS_AI.MODALS.CREATE_CANCEL.ACTION.CANCEL') }}</button>
            <button @click="confirmExitWithoutSaving" type="button" class="button action-button smooth alert">{{ $t('AGENTS_AI.MODALS.CREATE_CANCEL.ACTION.EXIT') }}</button>
          </div>
        </div>
      </woot-modal>
    </div>
  </div>
  </div>
</template>

<style scoped lang="scss">
/* Use :deep() instead of top-level ::v-deep block to avoid selector parsing issues */
:deep(.ProseMirror-menubar) {
  @apply hidden;
}
:deep(.ProseMirror-woot-style) {
  @apply min-h-[12.5rem];
}
:deep(.ProseMirror-woot-style) p {
  @apply text-base;
}

/* Forzar que el widget del agente de prueba se incruste en el contenedor derecho */
:deep(.woot-widget-holder),
:deep(.woot--bubble-holder) {
  position: static !important;
  inset: auto !important;
  width: 100% !important;
  max-width: 100% !important;
  height: 100% !important;
  max-height: 100% !important;
}

:deep(.woot-widget-holder) iframe {
  position: static !important;
  width: 100% !important;
  height: 100% !important;
}
</style>
