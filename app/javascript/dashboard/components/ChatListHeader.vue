<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch, getCurrentInstance } from 'vue';
import store from 'dashboard/store';
import ConversationBasicFilter from './widgets/conversation/ConversationBasicFilter.vue';
import whatsappInstancesClient from '../api/channel/whatsappInstancesClient';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  pageTitle: { type: String, required: true },
  channelName: { type: String, required: true },
  channelType: { type: String, required: true, default: '' },
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  activeStatus: { type: String, required: true },
});

const checking = ref(false);
const connectionStatus = ref('disconnected');
const lastError = ref('');
const showQR = ref(false);
const qrCode = ref('');
const qrImageLoaded = ref(false);
const acting = ref(false);

const currentUser = computed(() => store.getters['getCurrentUser']);
const accountId = computed(() => store.getters['getCurrentAccountId']);
let statusInterval = null;

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'basicFilterChange',
  'filtersModal',
]);

const onBasicFilterChange = (value, type) => emit('basicFilterChange', value, type);

const clearStatusPolling = () => {
  if (statusInterval) {
    clearInterval(statusInterval);
    statusInterval = null;
  }
};

// ✅ Normaliza estados: 'open/connected/online' => connected; 'connecting', vacíos o desconocidos => disconnected
const normalizeState = (instance) => {
  if (!instance) return 'disconnected'; // instancia no existe o null
  const raw = (instance?.state || instance?.connection || '')
    .toString()
    .toLowerCase();

  if (['open', 'connected', 'online'].includes(raw)) return 'connected';

  // cualquier otro (connecting, qr, offline, etc.) => desconectado
  if (['connecting', 'close', 'closed', 'offline', 'qr', 'disconnected'].includes(raw)) {
    return 'disconnected';
  }

  return 'disconnected';
};

const startStatusPolling = () => {
  if (props.channelType !== 'Channel::Api') return;
  if (statusInterval) clearInterval(statusInterval);
  statusInterval = setInterval(() => { checkState(); }, 3000);
};

const checkState = async () => {
  checking.value = true;
  lastError.value = '';
  try {
    const { data } = await whatsappInstancesClient.connectionState(props.channelName);
    const state = normalizeState(data?.instance);
    connectionStatus.value = state;

    if (state === 'connected') {
      showQR.value = false;
      clearStatusPolling();
    } else {
      startStatusPolling();
    }
  } catch (e) {
    const status = e?.response?.status;
    if (status === 404) {
      connectionStatus.value = 'disconnected'; // instancia no existe
    } else {
      lastError.value = e?.response?.data?.error || e?.message || 'Error consultando estado';
      connectionStatus.value = 'disconnected';
    }
    startStatusPolling();
  } finally {
    checking.value = false;
  }
};

const restartInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.restart(props.channelName);
    useAlert('Instancia reiniciada.');
    checkState();
    startStatusPolling();
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error al reiniciar';
    connectionStatus.value = 'disconnected';
    startStatusPolling();
  } finally {
    acting.value = false;
  }
};

const logoutInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.logout(props.channelName);
    connectionStatus.value = 'disconnected';
    startStatusPolling();
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error al cerrar sesión';
  } finally {
    acting.value = false;
  }
};

const showModal = async () => {
  showQR.value = true;
  createQr();
  startStatusPolling();
};

const createQr = async () => {
  try {
    const payload = {
      whatsapp_instance: {
        instance_name: props.channelName,
        chatwoot_account_id: accountId.value,
        chatwoot_token: currentUser.value?.access_token,
        chatwoot_url: 'https://easycontact.top',
        chatwoot_sign_msg: false,
        chatwoot_reopen_conversation: true,
        chatwoot_conversation_pending: true,
      },
    };
    const response = await whatsappInstancesClient.create(payload);

    const isOpen =
      response?.status === 'open' ||
      ['open', 'connected', 'online'].includes(
        (response?.data?.instance?.state || '').toLowerCase()
      );

    if (isOpen) {
      connectionStatus.value = 'connected';
      showQR.value = false;
      clearStatusPolling();
      return;
    }

    qrCode.value = response?.data?.qrcode?.base64 || response?.base64 || '';
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error generando QR';
  }
};

const { proxy } = getCurrentInstance();

onMounted(() => {
  checkState();
  startStatusPolling();
});

watch(
  () => proxy.$route.fullPath,
  () => {
    clearStatusPolling();
    checkState();
    startStatusPolling();
  }
);

// ✅ Al cambiar el canal, reinicia todo el flujo
watch(
  () => props.channelName,
  () => {
    clearStatusPolling();
    qrCode.value = '';
    showQR.value = false;
    connectionStatus.value = 'disconnected';
    checkState();
    startStatusPolling();
  }
);

onBeforeUnmount(() => {
  clearStatusPolling();
});

const hasAppliedFiltersOrActiveFolders = computed(
  () => props.hasAppliedFilters || props.hasActiveFolders
);

// ✅ Computed para el template
const isConnected = computed(() => connectionStatus.value === 'connected');
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-0"
    :class="{
      'pb-3 border-b border-slate-75 dark:border-slate-700':
        hasAppliedFiltersOrActiveFolders,
    }"
  >
    <div class="flex max-w-[85%] justify-center items-center">
      <h1
        class="text-xl font-medium break-words truncate text-black-900 dark:text-slate-100"
        :title="props.pageTitle"
      >
        {{ props.pageTitle }}
      </h1>

      <span
        v-if="!hasAppliedFiltersOrActiveFolders"
        class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
      >
        {{
          $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${props.activeStatus}.TEXT`)
        }}
      </span>

      <!-- ✅ Mostrar Restart/Logout SOLO cuando esté connected/open -->
      <woot-button
        v-if="channelType === 'Channel::Api' && isConnected"
        v-tooltip.bottom="$t('CHAT_LIST_HEADER.WHATSAPP_WEB.RESTART')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="sync"
        :is-loading="acting"
        :disabled="checking"
        @click="restartInstance"
      />
      <woot-button
        v-if="channelType === 'Channel::Api' && isConnected"
        v-tooltip.bottom="$t('CHAT_LIST_HEADER.WHATSAPP_WEB.LOGOUT')"
        size="tiny"
        variant="smooth"
        color-scheme="alert"
        icon="power"
        :is-loading="acting"
        :disabled="checking"
        @click="logoutInstance"
      />

      <!-- ✅ Botón Connect cuando NO está connected (incluye connecting o instancia inexistente) -->
      <woot-button
        v-if="channelType === 'Channel::Api' && !isConnected"
        variant="smooth"
        color-scheme="secondary"
        size="tiny"
        @click="showModal"
      >
        {{$t('CHAT_LIST_HEADER.WHATSAPP_WEB.CONNECT')}}
      </woot-button>
    </div>

    <div class="flex items-center gap-1">
      <div v-if="props.hasAppliedFilters && !props.hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="save"
          @click="emit('addFolders')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="dismiss-circle"
          @click="emit('resetFilters')"
        />
      </div>

      <div v-if="props.hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="edit"
          @click="emit('filtersModal')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="delete"
          @click="emit('deleteFolders')"
        />
      </div>

      <woot-button
        v-else
        v-tooltip.right="$t('FILTER.TOOLTIP_LABEL')"
        variant="smooth"
        color-scheme="secondary"
        icon="filter"
        size="tiny"
        @click="emit('filtersModal')"
      />

      <ConversationBasicFilter
        v-if="!hasAppliedFiltersOrActiveFolders"
        @changeFilter="onBasicFilterChange"
      />
    </div>

    <woot-modal :show.sync="showQR" :on-close="() => { showQR = false; }">
      <woot-modal-header>
        <h3 class="text-lg font-semibold w-full text-center">
          {{$t("CHAT_LIST_HEADER.WHATSAPP_WEB.TITLE")}}
        </h3>
      </woot-modal-header>

      <div class="px-8 pb-8">
        <div
          class="mx-auto aspect-square w-[min(80vw,420px)] max-h-[min(80vh,420px)] flex items-center justify-center"
        >
          <img
            v-if="qrCode"
            :src="qrCode"
            alt="Código QR"
            class="w-full h-full object-contain border p-3 rounded-lg shadow-sm bg-white dark:bg-slate-900"
            @load="qrImageLoaded = true"
            @error="qrImageLoaded = false"
          />

          <div
            v-else
            class="w-full h-full grid place-items-center border rounded-lg bg-slate-50 dark:bg-slate-800"
          >
            <span class="text-sm text-slate-500 dark:text-slate-300">
              {{$t("CHAT_LIST_HEADER.WHATSAPP_WEB.LOADING")}}
            </span>
          </div>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
