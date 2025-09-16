<script setup>
import { ref, computed,onMounted, onBeforeUnmount, watch, getCurrentInstance } from 'vue';
import store from 'dashboard/store';
import ConversationBasicFilter from './widgets/conversation/ConversationBasicFilter.vue';
import whatsappInstancesClient from '../api/channel/whatsappInstancesClient';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  pageTitle: { type: String, required: true },
  channelType: { type: String, required: true, default: '' },
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  activeStatus: { type: String, required: true },
});

const checking = ref(false);
const connectionStatus = ref('unknown');
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
  'foldersModal', // lo usas en el template
]);

const onBasicFilterChange = (value, type) => {
  emit('basicFilterChange', value, type);
};

const hideQR = () => {
  showQR.value = false;
  if (connectionStatus.value === 'disconnected') {
    logoutInstance();
  }
  clearStatusPolling();
};

onMounted(async () => {
  // await checkState();
});

// const { proxy } = getCurrentInstance();
// watch(
//   () => proxy.$route.fullPath,
//   () => {
//     clearStatusPolling();
//     checkState();
//   }
// );

// onBeforeUnmount(() => {
//   clearStatusPolling();
//   logoutInstance();
// });

const clearStatusPolling = () => {
  if (statusInterval) {
    clearInterval(statusInterval);
  }
};

const normalizeState = data => {
  const raw = (data?.state || data?.connection || '').toString().toLowerCase();
  if (['connected', 'open', 'online'].includes(raw)) return 'connected';
  if (['connecting','disconnected', 'close', 'offline', 'qr'].includes(raw))
    return 'disconnected';
  if (data === true) return 'connected';
  if (data === false) return 'disconnected';
  return 'unknown';
};

const startStatusPolling = () => {
  if (statusInterval) {
    clearInterval(statusInterval)
  };
  statusInterval = setInterval(checkState, 3000);
}

const checkState = async () => {
  checking.value = true;
  lastError.value = '';
  try {
    const { data } = await whatsappInstancesClient.connectionState(props.pageTitle);
    if (data?.instance?.state === 'open') {
      connectionStatus.value = normalizeState(data?.instance);
      // hideQR();
      // clearStatusPolling();
    }
  } catch (e) {
    lastError.value =
      e?.response?.data?.error || e?.message || 'Error consultando estado';
    connectionStatus.value = 'disconnected';
  } finally {
    checking.value = false;
  }
};

const restartInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.restart(props.pageTitle);
    useAlert('Instancia reiniciada.');
  } catch (e) {
    lastError.value =
      e?.response?.data?.error || e?.message || 'Error al reiniciar';
    console.log(lastError.value, 'error');
    connectionStatus.value = 'disconnected';
  } finally {
    acting.value = false;
  }
};

const logoutInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.logout(props.pageTitle);
    connectionStatus.value = 'disconnected';
  } catch (e) {
    lastError.value =
      e?.response?.data?.error || e?.message || 'Error al cerrar sesión';
    console.log(lastError.value, 'error');
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
        instance_name: props.pageTitle,
        chatwoot_account_id: accountId.value,
        chatwoot_token: currentUser.value?.access_token,
        chatwoot_url: 'https://easycontact.top',
        chatwoot_sign_msg: false,
        chatwoot_reopen_conversation: true,
        chatwoot_conversation_pending: true,
      },
    };
    const response = await whatsappInstancesClient.create(payload);
    if (response?.status === 'open') {
      connectionStatus.value = 'connected';
      showQR.value = false;
      return;
    }

    qrCode.value = response?.data?.qrcode?.base64 || response?.base64 || '';
  } catch (e) {
    lastError.value =
      e?.response?.data?.error || e?.message || 'Error generando QR';
  }
};

const hasAppliedFiltersOrActiveFolders = computed(
  () => props.hasAppliedFilters || props.hasActiveFolders
);
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

  </div>
</template>
