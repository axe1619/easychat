<script>
import { mapGetters } from 'vuex';

export default {
  data() {
    return {
      expandedSection: 1,
      completedSteps: [],
      inviteRows: [{ email: '', accessLevel: '', invited: false }],
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),
    userName() {
      return this.currentUser?.name || '';
    },
    progressCompleted() {
      return this.completedSteps.length;
    },
    progressText() {
      return this.$t('ONBOARDING.PROGRESS', {
        completed: this.progressCompleted,
        total: 4,
      });
    },
  },
  methods: {
    async refreshCompletionFromBackend() {
      const steps = new Set(this.completedSteps);

      // Paso 1: tiene al menos un canal (inbox) creado
      try {
        await this.$store.dispatch('inboxes/get');
        const inboxes = this.$store.getters['inboxes/getInboxes'] || [];
        if (inboxes.length > 0) {
          steps.add(1);
        }
      } catch (e) {
        // ignorar errores de carga
      }

      // Paso 3: tiene al menos un agente IA creado
      try {
        await this.$store.dispatch('agentBots/get');
        const bots = this.$store.getters['agentBots/getBots'] || [];
        if (bots.length > 0) {
          steps.add(3);
        }
      } catch (e) {
        // ignorar errores de carga
      }

      // Paso 4: se ha enviado al menos una invitación (a nivel de UI)
      if (this.inviteRows.some(row => row.invited)) {
        steps.add(4);
      }

      this.completedSteps = Array.from(steps).sort((a, b) => a - b);
    },
    isExpanded(idx) {
      return this.expandedSection === idx;
    },
    toggleSection(idx) {
      this.expandedSection = this.expandedSection === idx ? 0 : idx;
    },
    markComplete(idx) {
      if (!this.completedSteps.includes(idx)) {
        this.completedSteps = [...this.completedSteps, idx].sort((a, b) => a - b);
      }
    },
    isComplete(idx) {
      return this.completedSteps.includes(idx);
    },
    openRouteInNewTab(route) {
      if (!route) return;
      const resolved = this.$router.resolve(route);
      const url = resolved && resolved.href ? resolved.href : null;
      if (url) {
        window.open(url, '_blank', 'noopener');
      }
    },
    settingsInboxNew() {
      return { name: 'settings_inbox_new' };
    },
    settingsAgentsIA() {
      return { name: 'settings_agents_ia' };
    },
    settingsAgentsIATemplatesUrl() {
      if (!this.accountId) return null;
      const base = window.location.origin || '';
      return `${base}/app/accounts/${this.accountId}/settings/agents-ia/templates`;
    },
    settingsTeams() {
      return { name: 'settings_teams_list' };
    },
    addInviteRow() {
      this.inviteRows.push({ email: '', accessLevel: '', invited: false });
    },
    async handleOpenChannels() {
      this.openRouteInNewTab(this.settingsInboxNew());
      // Recalcular el estado de completado desde backend
      setTimeout(() => {
        this.refreshCompletionFromBackend();
      }, 2000);
    },
    async handleOpenLifecycleCustomize() {
      this.openRouteInNewTab({ name: 'attributes_list' });
      this.markComplete(2);
    },
    async handleOpenAgentsIA() {
      const url = this.settingsAgentsIATemplatesUrl();
      if (url) {
        window.open(url, '_blank', 'noopener');
      }
      setTimeout(() => {
        this.refreshCompletionFromBackend();
      }, 2000);
    },
    inviteRow(index) {
      const row = this.inviteRows[index];
      if (!row || row.invited || !row.email || !row.accessLevel) return;

      // Aquí se podría llamar a una API de invitaciones cuando exista.
      this.$set(this.inviteRows, index, { ...row, invited: true });
      this.markComplete(4);
      this.refreshCompletionFromBackend();
    },
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 overflow-auto bg-slate-50 dark:bg-slate-900">
    <div class="max-w-6xl mx-auto p-6 lg:p-8">
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <!-- Left: Greeting + Steps -->
        <div class="xl:col-span-2 space-y-6">
          <!-- Greeting + Progress -->
          <div class="flex flex-wrap items-start justify-between gap-4">
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
              {{ $t('ONBOARDING.PAGE_GREETING', { name: userName }) }}
            </h1>
            <span class="text-sm font-medium text-slate-500 dark:text-slate-400">
              {{ progressText }}
            </span>
          </div>
          <div class="h-1.5 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden max-w-xs">
            <div
              class="h-full bg-woot-500 rounded-full transition-all duration-300"
              :style="{ width: `${(progressCompleted / 4) * 100}%` }"
            />
          </div>

          <!-- Section 1: Conecta canales -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
          >
            <button
              type="button"
              class="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors"
              @click="toggleSection(1)"
            >
              <span
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center border-2 border-slate-300 dark:border-slate-600"
                :class="isComplete(1) ? 'bg-woot-500 border-woot-500' : ''"
              >
                <fluent-icon
                  v-if="isComplete(1)"
                  icon="checkmark"
                  class="text-white"
                  size="16"
                />
              </span>
              <span class="flex-1 font-semibold text-slate-900 dark:text-white">
                {{ $t('ONBOARDING.SECTION_CHANNELS_TITLE') }}
              </span>
              <fluent-icon
                :icon="isExpanded(1) ? 'chevron-up' : 'chevron-down'"
                class="text-slate-500"
                size="20"
              />
            </button>
            <div v-if="isExpanded(1)" class="px-5 pb-5 pt-0">
              <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
                {{ $t('ONBOARDING.SECTION_CHANNELS_DESCRIPTION') }}
              </p>
              <button
                type="button"
                class="inline-flex items-center gap-2 px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white text-sm font-medium rounded-lg transition-colors"
                @click="handleOpenChannels"
              >
                {{ $t('ONBOARDING.SECTION_CHANNELS_BUTTON') }}
              </button> 
            </div>
          </div>

          <!-- Section 2: Ciclo de vida -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
          >
            <button
              type="button"
              class="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors"
              @click="toggleSection(2)"
            >
              <span
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center border-2 border-slate-300 dark:border-slate-600"
                :class="isComplete(2) ? 'bg-woot-500 border-woot-500' : ''"
              >
                <fluent-icon
                  v-if="isComplete(2)"
                  icon="checkmark"
                  class="text-white"
                  size="16"
                />
              </span>
              <span class="flex-1 font-semibold text-slate-900 dark:text-white">
                {{ $t('ONBOARDING.SECTION_LIFECYCLE_TITLE') }}
              </span>
              <fluent-icon
                :icon="isExpanded(2) ? 'chevron-up' : 'chevron-down'"
                class="text-slate-500"
                size="20"
              />
            </button>
            <div v-if="isExpanded(2)" class="px-5 pb-5 pt-0 space-y-4">
              <p class="text-sm text-slate-600 dark:text-slate-400">
                {{ $t('ONBOARDING.SECTION_LIFECYCLE_DESCRIPTION') }}
              </p>
              <div>
                <p class="text-sm font-semibold text-slate-900 dark:text-white mb-1">
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_STAGES_TITLE') }}
                </p>
                <p class="text-sm text-slate-600 dark:text-slate-400 mb-2">
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_STAGES_DESC') }}
                </p>
                <div class="flex flex-wrap gap-2">
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200">
                    🆕 New Lead
                  </span>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200">
                    🔥 Hot Lead
                  </span>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200">
                    💳 Payment
                  </span>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200">
                    😊 Customer
                  </span>
                </div>
              </div>
              <div>
                <p class="text-sm font-semibold text-slate-900 dark:text-white mb-1">
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_LOST_TITLE') }}
                </p>
                <p class="text-sm text-slate-600 dark:text-slate-400 mb-2">
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_LOST_DESC') }}
                </p>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200">
                  🧊 Cold Lead
                </span>
              </div>
              <div class="flex gap-2 pt-2">
                <button
                  v-if="!isComplete(2)"
                  type="button"
                  class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white text-sm font-medium rounded-lg transition-colors"
                  @click="markComplete(2)"
                >
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_BUTTON_GOT_IT') }}
                </button>
                <button
                  type="button"
                  class="inline-flex items-center px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 text-sm font-medium rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                  @click="handleOpenLifecycleCustomize"
                >
                  {{ $t('ONBOARDING.SECTION_LIFECYCLE_BUTTON_CUSTOMIZE') }}
                </button> 
              </div>
            </div>
          </div>

          <!-- Section 3: Agentes IA -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
          >
            <button
              type="button"
              class="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors"
              @click="toggleSection(3)"
            >
              <span
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center border-2 border-slate-300 dark:border-slate-600"
                :class="isComplete(3) ? 'bg-woot-500 border-woot-500' : ''"
              >
                <fluent-icon
                  v-if="isComplete(3)"
                  icon="checkmark"
                  class="text-white"
                  size="16"
                />
              </span>
              <span class="flex-1 font-semibold text-slate-900 dark:text-white">
                {{ $t('ONBOARDING.SECTION_AI_TITLE') }}
              </span>
              <fluent-icon
                :icon="isExpanded(3) ? 'chevron-up' : 'chevron-down'"
                class="text-slate-500"
                size="20"
              />
            </button>
            <div v-if="isExpanded(3)" class="px-5 pb-5 pt-0">
              <ul class="space-y-2 mb-4">
                <li class="flex items-start gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <fluent-icon icon="chat" class="text-woot-500 flex-shrink-0 mt-0.5" size="18" />
                  {{ $t('ONBOARDING.SECTION_AI_BULLET_1') }}
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <fluent-icon icon="arrow-sync" class="text-woot-500 flex-shrink-0 mt-0.5" size="18" />
                  {{ $t('ONBOARDING.SECTION_AI_BULLET_2') }}
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <fluent-icon icon="people" class="text-woot-500 flex-shrink-0 mt-0.5" size="18" />
                  {{ $t('ONBOARDING.SECTION_AI_BULLET_3') }}
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <fluent-icon icon="book-search" class="text-woot-500 flex-shrink-0 mt-0.5" size="18" />
                  {{ $t('ONBOARDING.SECTION_AI_BULLET_4') }}
                </li>
              </ul>
              <button
                type="button"
                class="inline-flex items-center gap-2 px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white text-sm font-medium rounded-lg transition-colors"
                @click="handleOpenAgentsIA"
              >
                <fluent-icon icon="chat-add" size="18" />
                {{ $t('ONBOARDING.SECTION_AI_BUTTON') }}
              </button>  
            </div>
          </div>

          <!-- Section 4: Invita compañeros -->
          <div
            class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
          >
            <button
              type="button"
              class="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors"
              @click="toggleSection(4)"
            >
              <span
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center border-2 border-slate-300 dark:border-slate-600"
                :class="isComplete(4) ? 'bg-woot-500 border-woot-500' : ''"
              >
                <fluent-icon
                  v-if="isComplete(4)"
                  icon="checkmark"
                  class="text-white"
                  size="16"
                />
              </span>
              <span class="flex-1 font-semibold text-slate-900 dark:text-white">
                {{ $t('ONBOARDING.SECTION_TEAM_TITLE') }}
              </span>
              <fluent-icon
                :icon="isExpanded(4) ? 'chevron-up' : 'chevron-down'"
                class="text-slate-500"
                size="20"
              />
            </button>
            <div v-if="isExpanded(4)" class="px-5 pb-5 pt-0 space-y-4">
              <p class="text-sm text-slate-600 dark:text-slate-400">
                {{ $t('ONBOARDING.SECTION_TEAM_DESCRIPTION') }}
              </p>
              <a
                href="#"
                class="text-sm text-woot-500 hover:underline"
                @click.prevent
              >
                {{ $t('ONBOARDING.SECTION_TEAM_LINK') }}
              </a>
              <div class="space-y-3">
                <div
                  v-for="(row, i) in inviteRows"
                  :key="i"
                  class="flex flex-wrap items-end gap-3"
                >
                  <div class="flex-1 min-w-[180px]">
                    <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                      {{ $t('ONBOARDING.SECTION_TEAM_EMAIL_LABEL') }}
                    </label>
                    <input
                      v-model="row.email"
                      type="email"
                      class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                      :placeholder="$t('ONBOARDING.SECTION_TEAM_EMAIL_LABEL')"
                      :disabled="row.invited"
                    />
                  </div>
                  <div class="w-40">
                    <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                      {{ $t('ONBOARDING.SECTION_TEAM_ACCESS_LABEL') }}
                    </label>
                    <select
                      v-model="row.accessLevel"
                      class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-md bg-white dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                      :disabled="row.invited"
                    >
                      <option value="">
                        {{ $t('ONBOARDING.SECTION_TEAM_ACCESS_PLACEHOLDER') }}
                      </option>
                      <option value="admin">Administrador</option>
                      <option value="agent">Agente</option>
                    </select>
                  </div>
                  <div class="w-36">
                    <button
                      type="button"
                      class="w-full px-4 py-2 bg-slate-200 dark:bg-slate-600 hover:bg-slate-300 dark:hover:bg-slate-500 text-slate-700 dark:text-slate-200 text-sm font-medium rounded-md transition-colors flex items-center justify-center gap-1"
                      :disabled="row.invited || !row.email || !row.accessLevel"
                      @click="inviteRow(i)"
                    >
                      <template v-if="!row.invited">
                        {{ $t('ONBOARDING.SECTION_TEAM_INVITE_BUTTON') }}
                      </template>
                      <template v-else>
                        <span class="inline-flex items-center gap-1">
                          <fluent-icon icon="checkmark" size="14" />
                          <span>Invitado</span>
                        </span>
                      </template>
                    </button>
                  </div> 
                </div> 
                <button
                  type="button"
                  class="inline-flex items-center gap-1 text-sm text-woot-500 hover:text-woot-600 font-medium"
                  @click="addInviteRow"
                >
                  <fluent-icon icon="add" size="18" />
                  {{ $t('ONBOARDING.SECTION_TEAM_ADD_MORE') }}
                </button>
              </div>
              <a
                href="#"
                class="text-sm text-woot-500 hover:underline block"
                @click.prevent
              >
                {{ $t('ONBOARDING.SECTION_TEAM_LINK_CONFIG') }}
              </a>  
            </div>
          </div>
        </div>

        <!-- Right: Recursos -->
        <div class="xl:col-span-1">
          <div class="bg-white dark:bg-slate-800 rounded-xl shadow-md border border-slate-200 dark:border-slate-700 p-6 sticky top-6">
            <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-5">
              {{ $t('ONBOARDING.RESOURCES_TITLE') }}
            </h3>
            <ul class="space-y-0 list-none p-0 m-0">
              <li class="border-b border-slate-100 dark:border-slate-700 last:border-0">
                <a
                  href="#"
                  class="flex items-center gap-3 py-3 text-sm text-slate-700 dark:text-slate-300 hover:text-woot-500 dark:hover:text-woot-400 transition-colors no-underline"
                  @click.prevent
                >
                  <span class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                    <fluent-icon icon="play-circle" size="18" />
                  </span>
                  <span class="flex-1 leading-snug">{{ $t('ONBOARDING.RESOURCE_INBOX_INTRO') }}</span>
                </a>
              </li>
              <li class="border-b border-slate-100 dark:border-slate-700 last:border-0">
                <a
                  href="#"
                  class="flex items-center gap-3 py-3 text-sm text-slate-700 dark:text-slate-300 hover:text-woot-500 dark:hover:text-woot-400 transition-colors no-underline"
                  @click.prevent
                >
                  <span class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                    <fluent-icon icon="chat-bubbles-question" size="18" />
                  </span>
                  <span class="flex-1 leading-snug">{{ $t('ONBOARDING.RESOURCE_SUPPORT') }}</span>
                </a>
              </li>
              <li class="border-b border-slate-100 dark:border-slate-700 last:border-0">
                <a
                  href="#"
                  class="flex items-center gap-3 py-3 text-sm text-slate-700 dark:text-slate-300 hover:text-woot-500 dark:hover:text-woot-400 transition-colors no-underline"
                  @click.prevent
                >
                  <span class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                    <fluent-icon icon="desktop" size="18" />
                  </span>
                  <span class="flex-1 leading-snug">{{ $t('ONBOARDING.RESOURCE_DEMO') }}</span>
                </a>
              </li>
              <li class="border-b border-slate-100 dark:border-slate-700 last:border-0">
                <a
                  href="#"
                  class="flex items-center gap-3 py-3 text-sm text-slate-700 dark:text-slate-300 hover:text-woot-500 dark:hover:text-woot-400 transition-colors no-underline"
                  @click.prevent
                >
                  <span class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                    <fluent-icon icon="question-circle" size="18" />
                  </span>
                  <span class="flex-1 leading-snug">{{ $t('ONBOARDING.RESOURCE_HELP_CENTER') }}</span>
                </a>
              </li>
              <li class="border-b border-slate-100 dark:border-slate-700 last:border-0">
                <a
                  href="#"
                  class="flex items-center gap-3 py-3 text-sm text-slate-700 dark:text-slate-300 hover:text-woot-500 dark:hover:text-woot-400 transition-colors no-underline"
                  @click.prevent
                >
                  <span class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400">
                    <fluent-icon icon="document" size="18" />
                  </span>
                  <span class="flex-1 leading-snug">{{ $t('ONBOARDING.RESOURCE_VIDEO_GUIDES') }}</span>
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
