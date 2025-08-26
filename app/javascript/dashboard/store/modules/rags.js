import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import RagsAPI from '../../api/rags';
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
  getRags($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getRag: $state => ragId => {
    const [rag] = $state.records.filter(r => r.id === Number(ragId));
    return rag || {};
  },
  // Útil si quieres listarlos por bot sin repetir filtros en componentes
  getRagsByAgentBotId: $state => agentBotId => {
    const idNum = Number(agentBotId);
    return $state.records.filter(r => r.agent_bot_id === idNum);
  },
};

export const actions = {
  // lista -> acepta agent_bot_id y account_id (opcional)
  get: async ({ commit }, params = {}) => {
    commit(types.SET_RAG_UI_FLAG, { isFetching: true });
    try {
      const { data } = await RagsAPI.get(params);
      commit(types.SET_RAGS, data);
      return data;
    } finally {
      commit(types.SET_RAG_UI_FLAG, { isFetching: false });
    }
  },

  // obtiene uno y lo inyecta/actualiza en records
  show: async ({ commit }, id) => {
    commit(types.SET_RAG_UI_FLAG, { isFetchingItem: true });
    try {
      const { data } = await RagsAPI.show(id);
      commit(types.ADD_RAG, data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_RAG_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async ({ commit }, payload) => {
    commit(types.SET_RAG_UI_FLAG, { isCreating: true });
    try {
      const { data } = await RagsAPI.create(payload);
      commit(types.ADD_RAG, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_RAG_UI_FLAG, { isCreating: false });
    }
    return null;
  },

  update: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_RAG_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await RagsAPI.update(id, payload);
      commit(types.EDIT_RAG, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_RAG_UI_FLAG, { isUpdating: false });
    }
    return null;
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_RAG_UI_FLAG, { isDeleting: true });
    try {
      await RagsAPI.delete(id);
      commit(types.DELETE_RAG, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_RAG_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_RAG_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.ADD_RAG]($state, rag) {
    $state.records.unshift(rag);
  },
  [types.SET_RAGS]: MutationHelpers.set,
  [types.EDIT_RAG]: MutationHelpers.update,
  [types.DELETE_RAG]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
