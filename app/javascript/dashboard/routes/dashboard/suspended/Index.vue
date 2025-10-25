<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { onMounted } from 'vue';
import Auth from '../../../api/auth';

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

const logout = () => {
  Auth.logout();
}

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div class="items-center bg-slate-50 flex justify-center h-full w-full flex-col">
    <EmptyState
      style="padding: 0;"
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE',{ phone:'+591 61332756' })"
      :link="{ url:'https://wa.me/59161332756', message: $t('APP_GLOBAL.ACCOUNT_SUSPENDED.LINK')}"
    />
    <woot-button
      color-scheme="secondary"
      size="small"
      icon="power"
      @click="logout"
    >
      {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
    </woot-button>
  </div>
</template>
