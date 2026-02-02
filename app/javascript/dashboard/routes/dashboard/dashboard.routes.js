import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { routes as inboxRoutes } from './inbox/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';

const AppContainer = () => import('./Dashboard.vue');
const Captain = () => import('./Captain.vue');
const Suspended = () => import('./suspended/Index.vue');
const OnboardingPage = () => import('./OnboardingPage.vue');

export default {
  routes: [
    ...helpcenterRoutes.routes,
    {
      path: frontendURL('accounts/:account_id'),
      component: AppContainer,
      children: [
        {
          path: frontendURL('accounts/:accountId/onboarding'),
          name: 'onboarding',
          component: OnboardingPage,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: frontendURL('accounts/:accountId/captain'),
          name: 'captain',
          component: Captain,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        ...inboxRoutes,
        ...conversation.routes,
        ...settings.routes,
        ...contactRoutes,
        ...searchRoutes,
        ...notificationRoutes,
      ],
    },
    {
      path: frontendURL('accounts/:accountId/suspended'),
      name: 'account_suspended',
      meta: {
        permissions: ['administrator', 'agent'],
      },
      component: Suspended,
    },
  ],
};
