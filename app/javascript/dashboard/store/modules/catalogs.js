// dashboard/store/modules/catalogs.js
import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CatalogsAPI from '../../api/catalogs';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isBulkCreating: false,
    isBulkDeleting: false,
  },
};

export const getters = {
  getCatalogs: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
  getCatalog: $state => id => {
    const [item] = $state.records.filter(r => r.id === Number(id));
    return item || {};
  },
  getCatalogsByAgentBotId: $state => agentBotId => {
    console.log('Desde modules/getCatalogsByAgentBotId', agentBotId)
    return $state.records.filter(r => Number(r.agent_bot_id) === Number(agentBotId))
  },
  getCatalogsByBotAndAccount:
    $state =>
      ({ agent_bot_id, account_id }) =>
      {
        return $state.records.filter(
          r =>
            Number(r.agent_bot_id) === Number(agent_bot_id) &&
            Number(r.account_id) === Number(account_id)
        )
      }
};

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit(types.SET_CATALOG_UI_FLAG, { isFetching: true });
    try {
      const { data } = await CatalogsAPI.get(params);
      commit(types.SET_CATALOGS, data);
      return data;
    } catch (error) {
      console.log('ERROR ACTIONS.GET')
      console.log(error)
      console.log('ERROR ACTIONS.GET')
      return [];
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, id) => {
    commit(types.SET_CATALOG_UI_FLAG, { isFetchingItem: true });
    try {
      const { data } = await CatalogsAPI.show(id);
      commit(types.ADD_CATALOG, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async ({ commit }, payload) => {
    commit(types.SET_CATALOG_UI_FLAG, { isCreating: true });
    try {
      const { data } = await CatalogsAPI.create(payload);
      commit(types.ADD_CATALOG, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isCreating: false });
    }
  },

  bulkCreate: async ({ commit, dispatch }, { items, refreshWith } = {}) => {
    commit(types.SET_CATALOG_UI_FLAG, { isBulkCreating: true });
    try {
      const { data } = await CatalogsAPI.bulkCreate(items);
      // El bulk_create del backend devuelve created_ids + errors.
      // Para tener la lista actualizada, refrescamos si nos pasan filtros:
      if (refreshWith) {
        await dispatch('get', refreshWith);
      }
      return data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isBulkCreating: false });
    }
  },

  update: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_CATALOG_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await CatalogsAPI.update(id, payload);
      commit(types.EDIT_CATALOG, data);
      return data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_CATALOG_UI_FLAG, { isDeleting: true });
    try {
      await CatalogsAPI.delete(id);
      commit(types.DELETE_CATALOG, id);
      return true;
    } catch (error) {
      throwErrorMessage(error);
      return false;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isDeleting: false });
    }
  },

  bulkDestroy: async ({ commit, dispatch }, { ids, refreshWith } = {}) => {
    commit(types.SET_CATALOG_UI_FLAG, { isBulkDeleting: true });
    try {
      const { data } = await CatalogsAPI.bulkDestroy(ids);
      // Si quieres quitar localmente sin refetch:
      commit(types.DELETE_CATALOGS, ids);
      // O refrescar desde servidor con filtros:
      if (refreshWith) {
        await dispatch('get', refreshWith);
      }
      return data;
    } catch (error) {
      throwErrorMessage(error);
      return null;
    } finally {
      commit(types.SET_CATALOG_UI_FLAG, { isBulkDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CATALOG_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  [types.SET_CATALOGS]: MutationHelpers.set, // reemplaza toda la lista
  [types.ADD_CATALOG]: MutationHelpers.setSingleRecord,
  [types.EDIT_CATALOG]: MutationHelpers.update,
  [types.DELETE_CATALOG]: MutationHelpers.destroy,

  // eliminar muchos IDs
  [types.DELETE_CATALOGS]($state, ids) {
    const idSet = new Set(ids.map(Number));
    $state.records = $state.records.filter(r => !idSet.has(Number(r.id)));
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
