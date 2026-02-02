<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import TinyEditor from './widgets/TinyEditor.vue';
import Spinner from 'shared/components/Spinner.vue';
import ModalAgentRag from './components/agentRag/ModalAgentRag.vue';
import ModalAgentCalendar from './components/ModalAgentCalendar.vue';
import ModalAgentCatalog from './components/agentCatalog/ModalAgentCatalog.vue';
import axios from 'axios';
import { frontUrl } from './services/apiAgent';

export default {
  name: 'CreateAgent',
  components: { TinyEditor, Spinner, ModalAgentRag, ModalAgentCalendar, ModalAgentCatalog },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    const base = process.env.AGENTIC_EASY_CONTACT || '';
    return {
      agentName: '',
      agentDescription: '',
      agentPrompt: '',
      scheduleEnabled: false,
      initAt: '',
      finishAt: '',
      agent_type: 0,
      outgoing_url: `${base}/api/agent/maria`,
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      avatarUrl: null,
      isUploadingAvatar: false,
      editorKey: 0, // Key para forzar actualización del editor
      // Modals and validation flags
      showAgentRag: false,
      showAgentCalendar: false,
      showAgentCatalog: false,
      showCancelConfirm: false,
      showNoRagConfirm: false,

      templateDefs: [
        { id: 'receptionist', nameKey: 'RECEPTIONIST', descriptionKey: 'RECEPTIONIST_DESC', prompt: `# ROL Y ESTILO\n- Eres un recepcionista virtual amable y servicial.\n- Saluda a los contactos, identifica sus necesidades y captura los detalles esenciales.\n- Dirige las conversaciones al equipo o persona adecuada para obtener ayuda adicional.\n- Habla con claridad y mantén la calma.\n\n# INSTRUCCIONES\n- Formula solo una pregunta a la vez.\n- Si la consulta requiere un equipo específico, recopila la información necesaria antes de derivar.`, agent_type: 0, outgoing_url: `${base}/api/agent/maria` },
        { id: 'sales', nameKey: 'SALES_AGENT', descriptionKey: 'SALES_AGENT_DESC', prompt: `# ROL Y ESTILO\n- Eres un agente de ventas virtual atento y profesional.\n- Saluda a los clientes potenciales, conoce sus necesidades y sugiere productos adecuados.\n- Conecta con el equipo correspondiente cuando el cliente esté listo.\n- Sé amable y orientado a ayudar sin presionar.\n\n# INSTRUCCIONES\n- Formula una pregunta a la vez.\n- Escucha las necesidades antes de sugerir.`, agent_type: 1, outgoing_url: `${base}/api/agent/sales` },
        { id: 'support', nameKey: 'SUPPORT_AGENT', descriptionKey: 'SUPPORT_AGENT_DESC', prompt: `# ROL Y ESTILO\n- Eres un agente de soporte que responde preguntas sobre productos usando las fuentes de conocimiento.\n- Cuando sea necesario, deriva el caso a un humano sin problemas.\n- Sé claro, paciente y orientado a resolver.\n\n# INSTRUCCIONES\n- Usa la información de las fuentes de conocimiento para responder.\n- Si no puedes resolver, deriva amablemente a un agente humano.`, agent_type: 0, outgoing_url: `${base}/api/agent/maria` },
      ],
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
    '$route.query': {
      handler() {
        this.applyTemplateOrScratch();
      },
      deep: true,
    },
  },
  mounted() {
    this.applyTemplateOrScratch();
    // Load account-level data for Actions section
    this.refreshRags();
    this.loadCalendars();
    this.loadCatalogs();
  },
  activated() {
    this.applyTemplateOrScratch();
  },
  beforeDestroy() {
    if (this.avatarUrl && this.avatarUrl.startsWith('blob:')) {
      URL.revokeObjectURL(this.avatarUrl);
    }
  },
  methods: {
    applyTemplateOrScratch() {
      const tId = this.$route.query.template;
      const base = process.env.AGENTIC_EASY_CONTACT || '';
      // Incrementar key para forzar recreación del editor
      this.editorKey += 1;
      
      if (tId && ['receptionist', 'sales', 'support'].includes(tId)) {
        const t = this.templateDefs.find(x => x.id === tId);
        if (t) {
          this.agentName = this.$t('AGENTS_AI.TEMPLATES.ITEMS.' + t.nameKey);
          this.agentDescription = this.$t('AGENTS_AI.TEMPLATES.ITEMS.' + t.descriptionKey);
          this.agent_type = t.agent_type;
          this.outgoing_url = t.outgoing_url;
          this.scheduleEnabled = false;
          this.initAt = '';
          this.finishAt = '';
          
          // Forzar actualización del editor: primero limpiar, luego establecer el valor
          this.agentPrompt = '';
          this.$nextTick(() => {
            this.agentPrompt = t.prompt;
            // Asegurar que el editor se actualice después de establecer el valor
            this.$nextTick(() => {
              // Forzar actualización adicional si es necesario
              if (this.$refs.tinyEditor) {
                this.$refs.tinyEditor.$forceUpdate?.();
              }
            });
          });
        }
      } else {
        this.agentName = '';
        this.agentDescription = '';
        this.agentPrompt = '';
        this.scheduleEnabled = false;
        this.initAt = '';
        this.finishAt = '';
        this.agent_type = 0;
        this.outgoing_url = `${base}/api/agent/maria`;
        this.avatarUrl = null;
        this.avatarFile = null;
      }
      this.$nextTick(() => {
        if (this.v$ && this.v$.$reset) this.v$.$reset();
      });
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
    cancel() {
      // Si hay datos, mostrar modal de confirmación antes de salir
      if (this.agentName || this.agentDescription || this.agentPrompt || this.avatarFile) {
        this.showCancelConfirm = true;
        return;
      }
      this.$router.push({ name: 'settings_agents_ia' });
    },
    confirmExitWithoutSaving() {
      this.showCancelConfirm = false;
      this.$router.push({ name: 'settings_agents_ia' });
    },
    toggleScheduleEnabled() {
      if (!this.scheduleEnabled) {
        this.initAt = '';
        this.finishAt = '';
      }
      this.scheduleEnabled = !this.scheduleEnabled;
    },
    hideAgentRag() {
      this.showAgentRag = false;
      // Refresh account-level RAGs to reflect newly added sources
      this.refreshRags();
    },
    hideAgentCalendar() {
      this.showAgentCalendar = false;
      this.loadCalendars();
    },
    hideAgentCatalog() {
      this.showAgentCatalog = false;
      this.loadCatalogs();
    },
    hideCancelConfirm() {
      this.showCancelConfirm = false;
    },
    hideNoRagConfirm() {
      this.showNoRagConfirm = false;
    },

    // RAG methods (account-level)
    async refreshRags() {
      try {
        await this.$store.dispatch('rags/get', { account_id: this.accountId });
      } catch (e) {
        // ignore
      }
      this.agentRags = this.$store.getters['rags/getRags'] || [];
      try {
        const { data } = await axios.get(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/${this.accountId}-`);
        this.dbCollections = data.files || [];
      } catch (e) {
        console.error('Error loading RAG collections:', e);
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
      const id = this.idDeleteRag;
      const name = `${this.accountId}-${this.deleteNameRag}`;
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

    // Calendar methods (account-level)
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
      const newData = {
        account_id: this.accountId,
        ...data
      };
      await this.$store.dispatch('calendars/create', newData);
      await this.loadCalendars();
    },
    async deleteCalendar(id) {
      await this.$store.dispatch('calendars/delete', id);
      await this.loadCalendars();
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

    // helpers to load account-level calendars and catalogs
    async loadCalendars() {
      try {
        await this.$store.dispatch('calendars/get', { account_id: this.accountId });
        this.agentCalendars = this.$store.getters['calendars/getCalendarsByAccountId'](this.accountId) || this.$store.getters['calendars/getCalendars'] || [];
        this.outSyncGoogleAccount = !this.agentCalendars.some(i => i.platform === 'google');
      } catch (e) {
        console.error('Error loading calendars:', e);
      }
    },
    async loadCatalogs() {
      try {
        await this.$store.dispatch('catalogs/get', { account_id: this.accountId });
        this.agentCatalogs = this.$store.getters['catalogs/getCatalogsByAccountId'](this.accountId) || this.$store.getters['catalogs/getCatalogs'] || [];
      } catch (e) {
        console.error('Error loading catalogs:', e);
      }
    },
    async publish() {
      if (this.isButtonDisabled || this.isCreating) return;
      // Verificar si existen fuentes de conocimiento antes de publicar
      try {
        await this.$store.dispatch('rags/get', { account_id: this.accountId });
      } catch (err) {
        // ignore
      }
      const rags = this.$store.getters['rags/getRags'] || [];
      if (!rags || rags.length === 0) {
        this.showNoRagConfirm = true;
        return;
      }
      await this.doPublish();
    },
    async doPublish() {
      const data = {
        name: this.agentName,
        description: this.agentDescription,
        prompt: this.agentPrompt,
        agent_type: this.agent_type,
        outgoing_url: this.outgoing_url,
        init_at: this.scheduleEnabled ? this.initAt : '',
        finish_at: this.scheduleEnabled ? this.finishAt : '',
      };
      if (this.avatarFile instanceof File) {
        data.avatar = this.avatarFile;
      }
      try {
        await this.$store.dispatch('agentBots/create', data);
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.SUCCESS'));
        this.$router.replace({ name: 'settings_agents_ia' });
      } catch (error) {
        if (error?.response?.status === 402) {
          useAlert(this.$t('AGENTS_AI.PAYMENT_REQUIRED'));
          return;
        }
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.ERROR'));
      }
    },
    continuePublishWithoutRags() {
      this.showNoRagConfirm = false;
      this.doPublish();
    }
  },
  validations: {
    agentName: { required },
    agentPrompt: { required },
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 overflow-auto bg-slate-50 dark:bg-slate-900">
    <!-- Header -->
    <div class="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 px-6 py-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <button @click="cancel" class="text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white">
            <fluent-icon icon="arrow-left" size="20" />
          </button>
          <h1 class="text-xl font-bold text-slate-900 dark:text-white">
            {{ $t('AGENTS_AI.CREATE.TITLE') }}
          </h1>
        </div>
        <div class="flex items-center gap-3">
          <button
            @click="cancel"
            class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-md hover:bg-slate-50 dark:hover:bg-slate-600"
          >
            {{ $t('AGENTS_AI.CREATE.CANCEL') }}
          </button>
          <woot-button
            :disabled="isButtonDisabled || isCreating"
            :loading="isCreating"
            @click="publish"
            color-scheme="primary"
            icon="add-circle"
          >
            {{ $t('AGENTS_AI.CREATE.CREATE_BUTTON') }}
          </woot-button>
        </div>
      </div>
    </div>

    <div class="p-6 space-y-6">
      <!-- Configuration (single column, no Test Agent) -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 space-y-6 max-w-3xl">
        <div>
          <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-2">
            {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.TITLE') }}
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.DESCRIPTION') }}
          </p>
        </div>

        <!-- Imagen y Nombre -->
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
                :src="avatarUrl || avatarDefault"
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

        <!-- Instructions -->
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
            <TinyEditor :key="`prompt-editor-${editorKey}`" ref="tinyEditor" v-model="agentPrompt" :height="300" />
            <p v-if="v$.agentPrompt.$error" class="mt-1 text-sm text-red-600">
              {{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.PROMPT.ERROR') }}
            </p>
          </div>

        </div>

        <!-- Schedule -->
        <div class="flex items-center">
          <input
            id="scheduleEnabledIdCreate"
            v-model="scheduleEnabled"
            type="checkbox"
            @change="toggleScheduleEnabled"
            class="me-2"
          />
          <label for="scheduleEnabledIdCreate" class="text-sm text-slate-700 dark:text-slate-300">
            {{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.LABEL') }}
          </label>
        </div>
        <div v-if="scheduleEnabled" class="grid grid-cols-2 gap-4">
          <woot-input v-model="initAt" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.INIT')" type="time" />
          <woot-input v-model="finishAt" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.FINISH')" type="time" />
        </div>
      </div>

      <!-- Actions: capabilities-like UI with listing and management -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 max-w-3xl">
        <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-2">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.TITLE') }}</h2>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.DESCRIPTION') }}</p>

        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <!-- Knowledge Sources -->
          <h3 class="text-base font-semibold text-slate-900 dark:text-white mb-4">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.TITLE') }}</h3>

          <div v-if="!agentRags || agentRags.length === 0" class="space-y-4">
            <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 flex items-start gap-3">
              <fluent-icon icon="warning" size="20" class="text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
              <p class="text-sm text-amber-800 dark:text-amber-200">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_ALERT') }}</p>
            </div>
            <div class="text-center py-8">
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-700 mb-4">
                <fluent-icon icon="folder" size="32" class="text-slate-500 dark:text-slate-400" />
              </div>
              <h4 class="text-base font-semibold text-slate-900 dark:text-white mb-2">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_TITLE') }}</h4>
              <p class="text-sm text-slate-600 dark:text-slate-400 mb-4 max-w-md mx-auto">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_DESCRIPTION') }}</p>
              <woot-button color-scheme="primary" @click="showAgentRag = true">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.ADD_BUTTON') }}</woot-button>
            </div>
          </div>

          <div v-else>
            <div class="flex justify-end mb-4">
              <woot-button variant="smooth" color-scheme="primary" size="small" @click="showAgentRag = true">{{ $t('AGENTS_AI.CARDS.RAG.ADD') }}</woot-button>
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
                  <tr v-if="isFetchingRags">
                    <td colspan="2" class="py-4"><div class="flex justify-center items-center"><Spinner /></div></td>
                  </tr>
                  <tr v-else v-for="item in agentRags" :key="item.id" class="">
                    <td class="py-2 text-center">
                      <p class="text-center font-bold">{{ item.collection_name }} - {{ formatDate(item.created_at) }}</p>
                      <p class="font-semibold mt-2">{{ $t('AGENTS_AI.CARDS.RAG.FORM.LABEL_DESCRIPTION') }}</p>
                      <textarea v-if="item.id === idDescription" v-model="valueDescription" class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-white dark:bg-slate-700 text-slate-900 dark:text-white text-sm" :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')" />
                      <span v-else class="text-sm text-slate-600 dark:text-slate-400"> {{ item.description || '-' }}</span>
                    </td>
                    <td class="py-4 text-center">
                      <div v-if="isRagUpdating || isRagDeleting" class="flex justify-evenly items-center"><Spinner /></div>
                      <div v-else-if="item.id === idDescription" class="flex justify-evenly items-center">
                        <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark" @click="updateDescriptionRag" />
                        <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss" @click="desactiveEditDescription" />
                      </div>
                      <div v-else-if="item.id === idDeleteRag" class="flex justify-evenly items-center">
                        <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark" @click="deleteRag" />
                        <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss" @click="desactiveDeleteRag" />
                      </div>
                      <div v-else class="flex justify-evenly items-center">
                        <woot-button v-if="dbCollections.includes(item.collection_name)" size="tiny" variant="smooth" color-scheme="primary" icon="edit" @click="activeEditDescription(item.id, item.description)" />
                        <span v-else class="text-black-900 bg-yellow-300/80 rounded-[5px] p-[6px]"><fluent-icon icon="warning" size="12"/></span>
                        <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="delete" @click="activeDeleteRag(item.id, item.collection_name)" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Calendar -->
          <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-base font-semibold text-slate-900 dark:text-white">
                {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.CALENDAR.TITLE') }}
              </h3>
              <woot-button
                variant="smooth"
                color-scheme="primary"
                icon="add-circle"
                size="small"
                @click="showAgentCalendar = true"
              >
                {{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.ADD_GOOGLE_ACOUNT') }}
              </woot-button>
            </div>
            <div v-if="isFetchingCalendars" class="flex justify-center py-8"><Spinner /></div>
            <div v-else-if="agentCalendars && agentCalendars.length > 0" class="space-y-3">
              <div v-for="calendar in agentCalendars" :key="calendar.id" class="flex items-center justify-between p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                <div class="flex items-center gap-4">
                  <img :src="calendar.picture" class="w-12 h-12 rounded-full object-cover" />
                  <div>
                    <p class="font-semibold text-slate-900 dark:text-white">{{ calendar.user_name }}</p>
                    <p class="text-sm text-slate-600 dark:text-slate-400">{{ calendar.email }}</p>
                    <div v-if="calendar.platform === 'google'" class="mt-2 inline-block px-2 py-1 bg-slate-100 dark:bg-slate-700 rounded"><img src="/assets/images/dashboard/agents-ai/google.png" alt="Google" class="h-4" /></div>
                  </div>
                </div>
                <woot-button variant="smooth" color-scheme="alert" size="small" icon="delete" @click="deleteCalendar(calendar.id)">{{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.DELETE') }}</woot-button>
              </div>
            </div>
            <div v-else class="text-center py-8 text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENTS_AI.CARDS.CALENDAR.DESCRIPTION') }}</div>
          </div>

          <!-- Catalog -->
          <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-base font-semibold text-slate-900 dark:text-white">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.CATALOG.TITLE') }}</h3>
              <div class="flex gap-2">
                <woot-button variant="smooth" color-scheme="info" icon="upload" size="small" @click="showAgentCatalog = true">{{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}</woot-button>
                <woot-button variant="smooth" color-scheme="info" icon="download" size="small" @click="exportToCSV" :disabled="!agentCatalogs || agentCatalogs.length === 0">{{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_EXPORT') }}</woot-button>
              </div>
            </div>

            <div v-if="isFetchingCatalogs" class="flex justify-center py-8"><Spinner /></div>
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
                    <td v-for="(h, ci) in ['codigo', 'nombre', 'descripcion', 'precio', 'stock_disponible']" :key="ci" class="px-4 py-2 text-sm text-slate-700 dark:text-slate-300">{{ catalog[h] }}</td>
                  </tr>
                </tbody>
              </table>
              <p v-if="agentCatalogs.length > 5" class="text-sm text-slate-500 dark:text-slate-400 mt-2 text-center">{{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}: {{ agentCatalogs.length }} {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.PROGRESS') }}</p>
            </div>
            <div v-else class="text-center py-8 text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.DESCRIPTION_A') }}</div>
          </div>

        </div>
      </div>

      <!-- Modals for file uploads -->
      <woot-modal :show.sync="showAgentRag" :on-close="hideAgentRag">
        <ModalAgentRag :on-close="hideAgentRag" :botId="null" :accountId="accountId" />
      </woot-modal>

      <woot-modal :show.sync="showAgentCalendar" :on-close="hideAgentCalendar">
        <ModalAgentCalendar :on-close="hideAgentCalendar" :botId="null" :accountId="accountId" />
      </woot-modal>

      <woot-modal :show.sync="showAgentCatalog" :on-close="hideAgentCatalog">
        <ModalAgentCatalog :on-close="hideAgentCatalog" :botId="null" :accountId="accountId" />
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

      <!-- No knowledge sources modal -->
      <woot-modal :show.sync="showNoRagConfirm" :on-close="hideNoRagConfirm" size="small">
        <div class="pt-8 pl-8 pr-8 pb-4">
          <h2 class="text-lg font-semibold leading-6 text-slate-800 dark:text-slate-50">{{ $t('AGENTS_AI.MODALS.NO_RAGS.TITLE') }}</h2>
          <p class="mt-4 text-sm text-slate-600 dark:text-slate-300">{{ $t('AGENTS_AI.MODALS.NO_RAGS.BODY') }}</p>
          <div class="flex items-center justify-end gap-2 pt-6">
            <button @click="showNoRagConfirm = false" type="button" class="button action-button clear primary">{{ $t('AGENTS_AI.MODALS.NO_RAGS.ACTION.CANCEL') }}</button>
            <button @click="continuePublishWithoutRags" type="button" class="button action-button smooth primary">{{ $t('AGENTS_AI.MODALS.NO_RAGS.ACTION.CONTINUE') }}</button>
          </div>
        </div>
      </woot-modal>
      </div>
    </div>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar { @apply hidden; }
  .ProseMirror-woot-style { @apply min-h-[12.5rem]; p { @apply text-base; } }
}
</style>
