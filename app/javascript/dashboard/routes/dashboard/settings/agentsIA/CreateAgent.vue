<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import TinyEditor from './widgets/TinyEditor.vue';
import Spinner from 'shared/components/Spinner.vue';
import { uploadFile } from 'dashboard/helper/uploadHelper';

export default {
  name: 'CreateAgent',
  components: { TinyEditor, Spinner },
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
      showDescription: false,
      agent_type: 0,
      outgoing_url: `${base}/api/agent/maria`,
      showTemplatesDropdown: false,
      templateSearchQuery: '',
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      avatarUrl: null,
      isUploadingAvatar: false,
      editorKey: 0, // Key para forzar actualización del editor
      promptTemplates: [
        { id: 'general', titleKey: 'GENERAL', content: '# CONTEXT\n[Describe who the AI Agent is talking to and any key info it needs (e.g. company, conversation goal, business hours)]' },
        { id: 'communication', titleKey: 'COMMUNICATION', content: '# COMMUNICATION STYLE\n- Speak casually and use emojis where it feels natural.\n- Ask only one question at a time. Keep...' },
        { id: 'location', titleKey: 'LOCATION', content: '# BRANCHES ENQUIRIES\nIf a user asks about branches, only mention [e.g. North London (Camden), East London (Shoreditch)...]' },
        { id: 'hours', titleKey: 'HOURS', content: "# BUSINESS HOURS\nBusiness hours are [e.g. Monday-Friday, 9am-5pm]. If outside these timings, reply 'We're closed, but we..." }
      ],
      templateDefs: [
        { id: 'receptionist', nameKey: 'RECEPTIONIST', descriptionKey: 'RECEPTIONIST_DESC', prompt: `# ROL Y ESTILO\n- Eres un recepcionista virtual amable y servicial.\n- Saluda a los contactos, identifica sus necesidades y captura los detalles esenciales.\n- Dirige las conversaciones al equipo o persona adecuada para obtener ayuda adicional.\n- Habla con claridad y mantén la calma.\n\n# INSTRUCCIONES\n- Formula solo una pregunta a la vez.\n- Si la consulta requiere un equipo específico, recopila la información necesaria antes de derivar.`, agent_type: 0, outgoing_url: `${base}/api/agent/maria` },
        { id: 'sales', nameKey: 'SALES_AGENT', descriptionKey: 'SALES_AGENT_DESC', prompt: `# ROL Y ESTILO\n- Eres un agente de ventas virtual atento y profesional.\n- Saluda a los clientes potenciales, conoce sus necesidades y sugiere productos adecuados.\n- Conecta con el equipo correspondiente cuando el cliente esté listo.\n- Sé amable y orientado a ayudar sin presionar.\n\n# INSTRUCCIONES\n- Formula una pregunta a la vez.\n- Escucha las necesidades antes de sugerir.`, agent_type: 1, outgoing_url: `${base}/api/agent/sales` },
        { id: 'support', nameKey: 'SUPPORT_AGENT', descriptionKey: 'SUPPORT_AGENT_DESC', prompt: `# ROL Y ESTILO\n- Eres un agente de soporte que responde preguntas sobre productos usando las fuentes de conocimiento.\n- Cuando sea necesario, deriva el caso a un humano sin problemas.\n- Sé claro, paciente y orientado a resolver.\n\n# INSTRUCCIONES\n- Usa la información de las fuentes de conocimiento para responder.\n- Si no puedes resolver, deriva amablemente a un agente humano.`, agent_type: 0, outgoing_url: `${base}/api/agent/maria` },
      ],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agentBots/getUIFlags',
      accountId: 'getCurrentAccountId',
    }),
    isButtonDisabled() {
      return this.v$.agentName.$invalid || this.v$.agentPrompt.$invalid;
    },
    isCreating() {
      return (this.uiFlags && this.uiFlags.isCreating) || false;
    },
    filteredPromptTemplates() {
      const q = (this.templateSearchQuery || '').toLowerCase();
      if (!q) return this.promptTemplates;
      return this.promptTemplates.filter(t => {
        const title = this.$t('AGENTS_AI.CAPABILITIES.PROMPT_TEMPLATES.ITEMS.' + t.titleKey) || '';
        return title.toLowerCase().includes(q);
      });
    },
  },
  watch: {
    showTemplatesDropdown(val) {
      if (val) {
        this.$nextTick(() => document.addEventListener('click', this.handleTemplatesClickOutside));
      } else {
        document.removeEventListener('click', this.handleTemplatesClickOutside);
      }
    },
    '$route.query': {
      handler() {
        this.applyTemplateOrScratch();
      },
      deep: true,
    },
  },
  mounted() {
    this.applyTemplateOrScratch();
  },
  activated() {
    this.applyTemplateOrScratch();
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleTemplatesClickOutside);
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
          this.showDescription = false;
          
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
        this.showDescription = false;
        this.agent_type = 0;
        this.outgoing_url = `${base}/api/agent/maria`;
      }
      this.$nextTick(() => {
        if (this.v$ && this.v$.$reset) this.v$.$reset();
      });
    },
    triggerAvatarUpload() {
      this.$refs.avatarInput?.click();
    },
    async handleAvatarUpload(event) {
      const file = event.target.files?.[0];
      if (!file) return;
      
      // Validar que sea una imagen
      if (!file.type.startsWith('image/')) {
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_INVALID_TYPE') || 'Por favor selecciona un archivo de imagen');
        return;
      }
      
      // Validar tamaño (max 5MB)
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_SIZE_LIMIT') || 'La imagen no debe exceder 5MB');
        return;
      }
      
      this.isUploadingAvatar = true;
      try {
        const result = await uploadFile(file, this.accountId);
        this.avatarUrl = result.fileUrl;
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_UPLOAD_SUCCESS') || 'Imagen cargada correctamente');
      } catch (error) {
        console.error('Error uploading avatar:', error);
        useAlert(this.$t('AGENTS_AI.CREATE.AVATAR_UPLOAD_ERROR') || 'Error al cargar la imagen');
      } finally {
        this.isUploadingAvatar = false;
        // Reset input para permitir seleccionar el mismo archivo de nuevo
        if (event.target) {
          event.target.value = '';
        }
      }
    },
    cancel() {
      this.$router.push({ path: 'templates' });
    },
    toggleScheduleEnabled() {
      if (!this.scheduleEnabled) {
        this.initAt = '';
        this.finishAt = '';
      }
      this.scheduleEnabled = !this.scheduleEnabled;
    },
    toggleTemplatesDropdown() {
      this.showTemplatesDropdown = !this.showTemplatesDropdown;
      if (!this.showTemplatesDropdown) this.templateSearchQuery = '';
    },
    handleTemplatesClickOutside(event) {
      const el = this.$refs.templatesDropdownRef;
      if (el && !el.contains(event.target)) {
        this.showTemplatesDropdown = false;
        document.removeEventListener('click', this.handleTemplatesClickOutside);
      }
    },
    addPromptTemplate(t) {
      const sep = this.agentPrompt ? '\n\n' : '';
      this.agentPrompt = (this.agentPrompt || '') + sep + t.content;
      this.showTemplatesDropdown = false;
      this.templateSearchQuery = '';
    },
    async publish() {
      if (this.isButtonDisabled || this.isCreating) return;
      const data = {
        name: this.agentName,
        description: this.agentDescription,
        prompt: this.agentPrompt,
        agent_type: this.agent_type,
        outgoing_url: this.outgoing_url,
        init_at: this.scheduleEnabled ? this.initAt : '',
        finish_at: this.scheduleEnabled ? this.finishAt : '',
      };
      if (this.avatarUrl) {
        data.avatar_url = this.avatarUrl;
      }
      try {
        const created = await this.$store.dispatch('agentBots/create', data);
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.SUCCESS'));
        this.$router.replace({
          name: 'settings_agent_capabilities',
          query: { agent: created.id },
        });
      } catch (error) {
        if (error?.response?.status === 402) {
          useAlert(this.$t('AGENTS_AI.PAYMENT_REQUIRED'));
          return;
        }
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.ERROR'));
      }
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
          >
            {{ $t('AGENTS_AI.CREATE.PUBLISH') }}
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
                v-if="isUploadingAvatar"
                class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center"
              >
                <Spinner />
              </div>
              <div
                v-else
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

        <button
          @click="showDescription = !showDescription"
          class="text-sm text-woot-500 hover:text-woot-600 dark:text-woot-400 dark:hover:text-woot-300"
        >
          {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.SHOW_DESCRIPTION') }}
        </button>

        <div v-if="showDescription">
          <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">{{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.LABEL') }}</label>
          <textarea
            v-model="agentDescription"
            rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.PLACEHOLDER')"
          />
        </div>

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
          <div class="flex items-center gap-3 flex-wrap">
            <div ref="templatesDropdownRef" class="relative">
              <woot-button
                variant="smooth"
                color-scheme="secondary"
                size="small"
                icon="chevron-down"
                @click.stop="toggleTemplatesDropdown"
              >
                {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.ADD_TEMPLATES') }}
              </woot-button>
              <div v-if="showTemplatesDropdown" class="absolute left-0 top-full mt-1 z-30 w-96 max-h-[420px] bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-slate-200 dark:border-slate-700 flex flex-col overflow-hidden">
                <h4 class="px-4 py-3 text-sm font-semibold text-slate-900 dark:text-white border-b border-slate-200 dark:border-slate-700">{{ $t('AGENTS_AI.CAPABILITIES.PROMPT_TEMPLATES.TITLE') }}</h4>
                <div class="p-2 border-b border-slate-200 dark:border-slate-700">
                  <input
                    v-model="templateSearchQuery"
                    type="text"
                    :placeholder="$t('AGENTS_AI.CAPABILITIES.PROMPT_TEMPLATES.SEARCH_PLACEHOLDER')"
                    class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-md bg-white dark:bg-slate-900 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
                  />
                </div>
                <div class="flex-1 overflow-y-auto p-2">
                  <button
                    v-for="t in filteredPromptTemplates"
                    :key="t.id"
                    type="button"
                    @click.stop="addPromptTemplate(t)"
                    class="w-full text-left px-3 py-3 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 border-b border-slate-100 dark:border-slate-700 last:border-0 transition-colors"
                  >
                    <p class="text-sm font-semibold text-slate-900 dark:text-white">{{ $t('AGENTS_AI.CAPABILITIES.PROMPT_TEMPLATES.ITEMS.' + t.titleKey) }}</p>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1 line-clamp-2">{{ t.content }}</p>
                  </button>
                </div>
              </div>
            </div>
            <woot-button variant="smooth" color-scheme="primary" size="small" icon="graph">
              {{ $t('AGENTS_AI.CAPABILITIES.CONFIGURATION.INSTRUCTIONS.OPTIMIZE') }}
            </woot-button>
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

      <!-- Actions: solo aviso de fuentes de conocimiento -->
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-sm p-6 max-w-3xl">
        <h2 class="text-lg font-bold text-slate-900 dark:text-white mb-2">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.TITLE') }}</h2>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.DESCRIPTION') }}</p>
        <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
          <h3 class="text-base font-semibold text-slate-900 dark:text-white mb-4">{{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.TITLE') }}</h3>
          <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 flex items-start gap-3">
            <fluent-icon icon="warning" size="20" class="text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
            <p class="text-sm text-amber-800 dark:text-amber-200">
              {{ $t('AGENTS_AI.CAPABILITIES.ACTIONS.KNOWLEDGE_SOURCES.EMPTY_ALERT') }}
            </p>
          </div>
          <p class="text-sm text-slate-500 dark:text-slate-400 mt-3">
            {{ $t('AGENTS_AI.CREATE.KNOWLEDGE_AFTER_PUBLISH') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar { @apply hidden; }
  .ProseMirror-woot-style { @apply min-h-[12.5rem]; p { @apply text-base; } }
}
</style>
