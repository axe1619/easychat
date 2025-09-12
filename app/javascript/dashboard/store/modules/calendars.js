import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CalendarsAPI from '../../api/calendars';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getCalendars($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getCalendar:
    $state =>
    calendarId => {
      const [calendar] = $state.records.filter(r => r.id === Number(calendarId));
      return calendar || {};
    },
  // Útil para filtrar por bot sin repetir lógica en componentes
  getCalendarsByAgentBotId:
    $state =>
    agentBotId => {
      const idNum = Number(agentBotId);
      return $state.records.filter(r => r.agent_bot_id === idNum);
    },
};

export const actions = {
  // Lista -> acepta filtros como { agent_bot_id }
  get: async ({ commit }, params = {}) => {
    commit(types.SET_CALENDARS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await CalendarsAPI.get(params); // API: getAll
      commit(types.SET_CALENDARS, data);
      return data;
    } finally {
      commit(types.SET_CALENDARS_UI_FLAG, { isFetching: false });
    }
  },

  // Obtiene uno y lo inyecta/actualiza en records
  show: async ({ commit }, id) => {
    commit(types.SET_CALENDARS_UI_FLAG, { isFetchingItem: true });
    try {
      const { data } = await CalendarsAPI.show(id);
      commit(types.ADD_CALENDAR, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CALENDARS_UI_FLAG, { isFetchingItem: false });
    }
    return null;
  },

  create: async ({ commit }, payload) => {
    commit(types.SET_CALENDARS_UI_FLAG, { isCreating: true });
    try {
      const { data } = await CalendarsAPI.create(payload);
      commit(types.ADD_CALENDAR, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CALENDARS_UI_FLAG, { isCreating: false });
    }
    return null;
  },

  update: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_CALENDARS_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await CalendarsAPI.update(id, payload);
      commit(types.EDIT_CALENDAR, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CALENDARS_UI_FLAG, { isUpdating: false });
    }
    return null;
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_CALENDARS_UI_FLAG, { isDeleting: true });
    try {
      await CalendarsAPI.delete(id);
      commit(types.DELETE_CALENDAR, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CALENDARS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CALENDARS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.ADD_CALENDAR]($state, calendar) {
    $state.records.unshift(calendar);
  },
  [types.SET_CALENDARS]: MutationHelpers.set,
  [types.EDIT_CALENDAR]: MutationHelpers.update,
  [types.DELETE_CALENDAR]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
