import Vue from 'vue';
import * as types from '../mutation-types';

const state = {
  currentPage: {
    me: 0,
    unassigned: 0,
    all: 0,
    unread: 0,
    appliedFilters: 0,
    board: {}
  },
  hasEndReached: {
    me: false,
    unassigned: false,
    all: false,
    unread: false,
    board: {}
  },
};

export const getters = {
  getHasEndReachedBoard: $state => filter => {
    if ($state.hasEndReached.board[filter] == undefined) {
      return false
    }
    return $state.hasEndReached.board[filter]
  },
  getCurrentPageBoardFilter: $state => filter => {
    if ($state.currentPage.board[filter] == undefined) {
      return 0
    }
    return $state.currentPage.board[filter]
  },
  getHasEndReached: $state => filter => {
    return $state.hasEndReached[filter];
  },
  getCurrentPageFilter: $state => filter => {
    return $state.currentPage[filter];
  },
  getCurrentPage: $state => {
    return $state.currentPage;
  },
};

export const actions = {
  setCurrentPageBoard({ commit }, { filter, page }) {
    commit(types.default.SET_CURRENT_PAGE_BOARD, { filter, page });
  },
  setEndReachedBoard({ commit }, { filter }) {
    commit(types.default.SET_CONVERSATION_BOARD_END_REACHED, { filter });
  },
  clearCurrentPageBoard({ commit }){
    commit(types.default.CLEAR_CURRENT_PAGE_BOARD);
  },
  clearEndReachedBoard({ commit }){
    commit(types.default.CLEAR_CONVERSATION_BOARD_END_REACHED);
  },
  setCurrentPage({ commit }, { filter, page }) {
    commit(types.default.SET_CURRENT_PAGE, { filter, page });
  },
  setEndReached({ commit }, { filter }) {
    commit(types.default.SET_CONVERSATION_END_REACHED, { filter });
  },
  reset({ commit }) {
    commit(types.default.CLEAR_CONVERSATION_PAGE);
  },
};

export const mutations = {
  [types.default.SET_CURRENT_PAGE_BOARD]: ($state, { filter, page }) => {
    Vue.set($state.currentPage.board, filter, page);
  },
  [types.default.SET_CONVERSATION_BOARD_END_REACHED]: ($state, { filter }) => {
    Vue.set($state.hasEndReached.board, filter, true);
  },
  [types.default.CLEAR_CURRENT_PAGE_BOARD]: ($state) => {
    Vue.set($state.currentPage.board,{});
  },
  [types.default.CLEAR_CONVERSATION_BOARD_END_REACHED]: ($state) => {
    Vue.set($state.hasEndReached.board, {});
  },
  [types.default.SET_CURRENT_PAGE]: ($state, { filter, page }) => {
    Vue.set($state.currentPage, filter, page);
  },
  [types.default.SET_CONVERSATION_END_REACHED]: ($state, { filter }) => {
    if (filter === 'all') {
      Vue.set($state.hasEndReached, 'unassigned', true);
      Vue.set($state.hasEndReached, 'me', true);
      Vue.set($state.hasEndReached, 'unread', true);
    }
    Vue.set($state.hasEndReached, filter, true);
  },
  [types.default.CLEAR_CONVERSATION_PAGE]: $state => {
    $state.currentPage = {
      me: 0,
      unassigned: 0,
      all: 0,
      unread: 0,
      appliedFilters: 0,
      board: {}
    };

    $state.hasEndReached = {
      me: false,
      unassigned: false,
      all: false,
      unread: false,
      appliedFilters: false,
      board: {}
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
