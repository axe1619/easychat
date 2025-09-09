import { frontendURL } from '../../../../helper/URLHelper';

// const SettingsWrapper = () => import('../SettingsWrapper.vue');
const SettingsWrapper = () => import('../Wrapper.vue');
const IndexAgentsAI = () => import('./Index.vue');
const Capabilities = () => import('./Capabilities.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agents-ia'),
      component: SettingsWrapper,
      props: params => {
        const showBackButton = params.name !== 'settings_agents_ia';
        return {
          headerTitle: 'AGENTS_AI.HEADER_INDEX.TITLE',
          headerButtonText: 'SETTINGS.INBOXES.NEW_INBOX',
          icon: 'credit-card-person',
          showNewButton: false,
          // newButtonRoutes: ['settings_agents_ia'],
          showBackButton,
        };
      },
      // props: {
      //   headerTitle: 'AGENTS_AI.HEADER_INDEX.TITLE',
      //   icon: 'credit-card-person',
      //   showNewButton: false,
      //   showBackButton,
      // },
      meta: {
        permissions: ['administrator'],
      },
      children: [
        {
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'settings_agents_ia',
          component: IndexAgentsAI,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'capabilities',
          name: 'settings_agent_capabilities',
          component: Capabilities,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
