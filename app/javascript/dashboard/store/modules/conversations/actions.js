import Vue from 'vue';
import types from '../../mutation-types';
import ConversationApi from '../../../api/inbox/conversation';
import MessageApi from '../../../api/inbox/message';
import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';
import { createPendingMessage } from 'dashboard/helper/commons';
import {
  buildConversationList,
  isOnMentionsView,
  isOnUnattendedView,
  isOnFoldersView,
  buildConversationListBoard,
} from './helpers/actionHelpers';
import messageReadActions from './actions/messageReadActions';
import messageTranslateActions from './actions/messageTranslateActions';
import * as Sentry from '@sentry/browser';
import router from '../../../routes';
import agentCloud from '../../../api/agentCloud';

const TYPE_LIST = {
  SET_ALL_MESSAGES_LOADED: {
    default: types.SET_ALL_MESSAGES_LOADED,
    board: types.SET_ALL_MESSAGES_BOARD_LOADED
  },
  SET_PREVIOUS_CONVERSATIONS: {
    default: types.SET_PREVIOUS_CONVERSATIONS,
    board: types.SET_PREVIOUS_BOARD_CONVERSATIONS,
  },
  CLEAR_ALL_MESSAGES_LOADED: {
    default: types.CLEAR_ALL_MESSAGES_LOADED,
    board: types.CLEAR_ALL_MESSAGES_LOADED_BOARD
  },
  ADD_MESSAGE: {
    default: types.ADD_MESSAGE,
    board: types.ADD_MESSAGE_BOARD
  },
  ASSIGN_TEAM: {
    default: types.ASSIGN_TEAM,
    board: types.ASSIGN_TEAM_BOARD
  },
  ASSIGN_AGENT: {
    default: types.ASSIGN_AGENT,
    board: types.ASSIGN_AGENT_BOARD
  },
  ASSIGN_PRIORITY: {
    default: types.ASSIGN_PRIORITY,
    board: types.ASSIGN_PRIORITY_BOARD
  },
  SET_CONVERSATION_CAN_REPLY:{
    default: types.SET_CONVERSATION_CAN_REPLY,
    board: types.SET_CONVERSATION_BOARD_CAN_REPLY
  },
  UPDATE_CONVERSATION_LAST_ACTIVITY:{
    default: types.UPDATE_CONVERSATION_LAST_ACTIVITY,
    board: types.UPDATE_CONVERSATION_BOARD_LAST_ACTIVITY
  },
  UPDATE_CONVERSATION: {
    default: types.UPDATE_CONVERSATION,
    board: types.UPDATE_CONVERSATION_BOARD
  },
  ADD_CONVERSATION: {
    default: types.ADD_CONVERSATION,
    board: types.ADD_CONVERSATION_BOARD
  },
  UPDATE_PROPERTIES_CONVERSATION: {
    default: types.UPDATE_PROPERTIES_CONVERSATION,
    board: types.UPDATE_PROPERTIES_CONVERSATION_BOARD
  }
}

export const hasMessageFailedWithExternalError = pendingMessage => {
  // This helper is used to check if the message has failed with an external error.
  // We have two cases
  // 1. Messages that fail from the UI itself (due to large attachments or a failed network):
  //    In this case, the message will have a status of failed but no external error. So we need to create that message again
  // 2. Messages sent from Chatwoot but failed to deliver to the customer for some reason (user blocking or client system down):
  //    In this case, the message will have a status of failed and an external error. So we need to retry that message
  const { content_attributes: contentAttributes, status } = pendingMessage;
  const externalError = contentAttributes?.external_error ?? '';
  return status === MESSAGE_STATUS.FAILED && externalError !== '';
};

export const getTypeList = (type) => {
  let routeName = router.app._route.name;
  let useListConversation = "default"
  if (routeName.includes("board")) {
    useListConversation = "board"
  }
  return TYPE_LIST[type][useListConversation]
}

// actions
const actions = {
  getSuggestionMessage: async ({ commit }, payload) => {
    const { conversationId, count_responses } = payload
    const response = await agentCloud.getSuggestionMessage({ conversation_display_id: conversationId, count_responses });
    if (!response.data.status)
      return
    const messsages = JSON.parse(response.data.data);
    commit(types.SET_SUGGESTION_MESSAGE, messsages)
  },
  clearSuggestionMessage: ({ commit }) => {
    try {
      commit(types.CLEAR_SUGGESTION_MESSAGE);
    } catch (error) {
      console.warn({ error })
    }
  },
  setSelectedMessageSuggestion: ({ commit }, message) => {
    try {
      commit(types.SET_SELECTED_SUGGESTION_MESSAGE, message);
    } catch (error) {
      console.warn({ error })
    }
  },
  getConversation: async ({ commit }, conversationId) => {
    try {
      const response = await ConversationApi.show(conversationId);
      commit(getTypeList(types.UPDATE_CONVERSATION), response.data);
      commit(`contacts/${types.SET_CONTACT_ITEM}`, response.data.meta.sender);
    } catch (error) {
      // Ignore error
    }
  },

  fetchAllConversations: async ({ commit, state, dispatch }) => {
    commit(types.SET_LIST_LOADING_STATUS);
    try {
      const params = state.conversationFilters;
      const {
        data: { data },
      } = await ConversationApi.get(params);
      buildConversationList(
        { commit, dispatch },
        params,
        data,
        params.assigneeType
      );
    } catch (error) {
      // Handle error
    }
  },

  fetchConversationBoard: async ({ commit, state, dispatch }, params) => {
    const { filters, column } = params
    commit(types.SET_BOARD_LIST_LOADING_STATUS, column.id);
    try {
      const { data: { data } } = await ConversationApi.get(filters);
      buildConversationListBoard({ commit, dispatch }, params, data)
    } catch (error) {
      console.warn({ error })
    }
  },
  fetchUpdateKanbanStateConversation: async ({ commit, state, dispatch }, payload) => {
    const { params, kanbanState } = payload
    const { conversationId, ...attributes } = params
    try {
      await ConversationApi.update({ conversationId, attributes })
      commit(getTypeList(types.UPDATE_PROPERTIES_CONVERSATION), {
        conversationId,
        columnId: kanbanState.id,
        properties: {
          kanban_state: kanbanState
        }
      });
    } catch (error) {
      throw error;
    }
  },
  fetchUpdateAgentBot: async ({ commit, state, dispatch }, payload) => {
    const { conversationId, ...attributes } = payload
    await ConversationApi.update({ conversationId, attributes })
    commit(getTypeList(types.UPDATE_PROPERTIES_CONVERSATION), {
      conversationId,
      properties: {
        ...attributes,
      }
    })
  },
  fetchUpdateSentimentConversation: async ({ commit, state, dispatch }, payload) => {
    const { conversationId, last_sentiment_analysis, ...attributes } = payload
    const { data } = await ConversationApi.update({ conversationId, attributes: { ...attributes, last_sentiment_analysis } })
    commit(types.UPDATE_PROPERTIES_CONVERSATION, {
      conversationId,
      properties: {
        ...attributes,
        last_sentiment_analysis: data.last_sentiment_analysis
      }
    })
  },
  updatePropertiesConversation({ commit, state, dispatch }, payload) {
    try {
      commit(getTypeList(types.UPDATE_PROPERTIES_CONVERSATION), payload)
    } catch (error) {
      console.warn({ error })
    }
  },

  moveConversationBoard: ({ commit, state, dispatch }, payload) => {
    try {
      commit(types.MOVE_CONVERSATION_BOARD, payload)
    } catch (error) {
      console.warn({ error })
    }
  },

  clearConversationBoard({ commit }) {
    commit(types.CLEAR_CONVERSATION_BOARD);
  },
  fetchFilteredConversations: async ({ commit, dispatch }, params) => {
    commit(types.SET_LIST_LOADING_STATUS);
    try {
      const { data } = await ConversationApi.filter(params);
      buildConversationList(
        { commit, dispatch },
        params,
        data,
        'appliedFilters'
      );
    } catch (error) {
      // Handle error
    }
  },

  emptyAllConversations({ commit }) {
    commit(types.EMPTY_ALL_CONVERSATION);
  },

  clearSelectedState({ commit }) {
    commit(types.CLEAR_CURRENT_CHAT_WINDOW);
  },

  fetchPreviousMessages: async ({ commit }, data) => {
    try {
      const {
        data: { meta, payload },
      } = await MessageApi.getPreviousMessages(data);
      commit(`conversationMetadata/${types.SET_CONVERSATION_METADATA}`, {
        id: data.conversationId,
        data: meta,
      });
      commit(getTypeList(types.SET_PREVIOUS_CONVERSATIONS), {
        id: data.conversationId,
        data: payload,
      });
      if (!payload.length) {
        commit(getTypeList(types.SET_ALL_MESSAGES_LOADED));
      }
    } catch (error) {
      // Handle error
    }
  },

  fetchAllAttachments: async ({ commit }, conversationId) => {
    let attachments = null;

    try {
      const { data } = await ConversationApi.getAllAttachments(conversationId);
      attachments = data.payload;
    } catch (error) {
      // in case of error, log the error and continue
      Sentry.setContext('Conversation', {
        id: conversationId,
      });
      Sentry.captureException(error);
    } finally {
      // we run the commit even if the request fails
      // this ensures that the `attachment` variable is always present on chat
      commit(types.SET_ALL_ATTACHMENTS, {
        id: conversationId,
        data: attachments,
      });
    }
  },

  syncActiveConversationMessages: async (
    { commit, state, dispatch },
    { conversationId }
  ) => {
    const { allConversations, syncConversationsMessages } = state;
    const lastMessageId = syncConversationsMessages[conversationId];
    const selectedChat = allConversations.find(
      conversation => conversation.id === conversationId
    );
    if (!selectedChat) return;
    try {
      const { messages } = selectedChat;
      // Fetch all the messages after the last message id
      const {
        data: { meta, payload },
      } = await MessageApi.getPreviousMessages({
        conversationId,
        after: lastMessageId,
      });
      commit(`conversationMetadata/${types.SET_CONVERSATION_METADATA}`, {
        id: conversationId,
        data: meta,
      });
      // Find the messages that are not already present in the store
      const missingMessages = payload.filter(
        message => !messages.find(item => item.id === message.id)
      );
      selectedChat.messages.push(...missingMessages);
      // Sort the messages by created_at
      const sortedMessages = selectedChat.messages.sort((a, b) => {
        return new Date(a.created_at) - new Date(b.created_at);
      });
      commit(types.SET_MISSING_MESSAGES, {
        id: conversationId,
        data: sortedMessages,
      });
      commit(types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION, {
        conversationId,
        messageId: null,
      });
      dispatch('markMessagesRead', { id: conversationId }, { root: true });
    } catch (error) {
      // Handle error
    }
  },

  setConversationLastMessageId: async (
    { commit, state },
    { conversationId }
  ) => {
    const { allConversations } = state;
    const selectedChat = allConversations.find(
      conversation => conversation.id === conversationId
    );
    if (!selectedChat) return;
    const { messages } = selectedChat;
    const lastMessage = messages.last();
    if (!lastMessage) return;
    commit(types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION, {
      conversationId,
      messageId: lastMessage.id,
    });
  },

  async setActiveChat({ commit, dispatch }, { data, after }) {
    commit(types.SET_CURRENT_CHAT_WINDOW, data);
    commit(getTypeList(types.CLEAR_ALL_MESSAGES_LOADED))
    if (data.dataFetched === undefined) {
      try {
        await dispatch('fetchPreviousMessages', {
          after,
          before: data.messages[0].id,
          conversationId: data.id
        });
        Vue.set(data, 'dataFetched', true);
      } catch (error) {
        // Ignore error
      }
    }
  },

  assignAgent: async ({ dispatch }, { conversationId, agentId }) => {
    try {
      const response = await ConversationApi.assignAgent({
        conversationId,
        agentId,
      });
      dispatch('setCurrentChatAssigneeAdapter', { assignee: response.data });
    } catch (error) {
      // Handle error
    }
  },

  setCurrentChatAssigneeAdapter({ commit }, { assignee }) {
    commit(getTypeList(types.ASSIGN_AGENT), assignee);
  },

  setCurrentChatAssignee({ commit }, assignee) {
    commit(types.ASSIGN_AGENT, assignee);
  },

  assignTeam: async ({ dispatch }, { conversationId, teamId }) => {
    try {
      const response = await ConversationApi.assignTeam({
        conversationId,
        teamId,
      });
      dispatch('setCurrentChatTeam', { team: response.data, conversationId });
    } catch (error) {
      // Handle error
    }
  },

  setCurrentChatTeam({ commit }, { team, conversationId }) {
    commit(getTypeList(types.ASSIGN_TEAM), { team, conversationId });
  },

  assignStateRemarketing: async ({ dispatch }, { conversationId, state }) => {
    const attributes = { enabled_remarketing: state }
    await ConversationApi.update({ conversationId, attributes });
  },

  setCurrentChatStateRemarketing({ commit }, { state, conversationId }) {
    commit(types.ASSIGN_STATE_REMARKETING, { state, conversationId });
  },

  toggleStatus: async (
    { commit },
    { conversationId, status, snoozedUntil = null }
  ) => {
    try {
      const {
        data: {
          payload: {
            current_status: updatedStatus,
            snoozed_until: updatedSnoozedUntil,
          } = {},
        } = {},
      } = await ConversationApi.toggleStatus({
        conversationId,
        status,
        snoozedUntil,
      });
      commit(types.CHANGE_CONVERSATION_STATUS, {
        conversationId,
        status: updatedStatus,
        snoozedUntil: updatedSnoozedUntil,
      });
    } catch (error) {
      // Handle error
    }
  },

  createPendingMessageAndSend: async ({ dispatch }, data) => {
    const pendingMessage = createPendingMessage(data);
    dispatch('sendMessageWithData', pendingMessage);
  },

  sendMessageWithData: async ({ commit }, pendingMessage) => {
    const { conversation_id: conversationId, id } = pendingMessage;
    try {
      commit(getTypeList(types.ADD_MESSAGE), {
        ...pendingMessage,
        status: MESSAGE_STATUS.PROGRESS,
      });
      const response = hasMessageFailedWithExternalError(pendingMessage)
        ? await MessageApi.retry(conversationId, id)
        : await MessageApi.create(pendingMessage);
      commit(getTypeList(types.ADD_MESSAGE), {
        ...response.data,
        status: MESSAGE_STATUS.SENT,
      });
      commit(types.ADD_CONVERSATION_ATTACHMENTS, {
        ...response.data,
        status: MESSAGE_STATUS.SENT,
      });
    } catch (error) {
      const errorMessage = error.response
        ? error.response.data.error
        : undefined;
      commit(getTypeList(types.ADD_MESSAGE), {
        ...pendingMessage,
        meta: {
          error: errorMessage,
        },
        status: MESSAGE_STATUS.FAILED,
      });
      throw error;
    }
  },

  addMessage({ commit }, message) {
    commit(getTypeList(types.ADD_MESSAGE) , message);
    if (message.message_type === MESSAGE_TYPE.INCOMING) {
      commit(getTypeList(types.SET_CONVERSATION_CAN_REPLY), {
        conversationId: message.conversation_id,
        canReply: true,
        kanban_state: message.kanban_state
      });
      commit(types.ADD_CONVERSATION_ATTACHMENTS, message);
    }
  },

  updateMessage({ commit }, message) {
    commit(getTypeList(types.ADD_MESSAGE) , message);
  },

  deleteMessage: async function deleteLabels(
    { commit },
    { conversationId, messageId }
  ) {
    try {
      const { data } = await MessageApi.delete(conversationId, messageId);
      commit(getTypeList(types.ADD_MESSAGE) , data);
      commit(types.DELETE_CONVERSATION_ATTACHMENTS, data);
    } catch (error) {
      throw new Error(error);
    }
  },

  addConversation({ commit, state, dispatch, rootState }, conversation) {
    const { currentInbox, appliedFilters } = state;
    const {
      inbox_id: inboxId,
      meta: { sender },
    } = conversation;
    const hasAppliedFilters = !!appliedFilters.length;
    const isMatchingInboxFilter =
      !currentInbox || Number(currentInbox) === inboxId;
    if (
      !hasAppliedFilters &&
      !isOnFoldersView(rootState) &&
      !isOnMentionsView(rootState) &&
      !isOnUnattendedView(rootState) &&
      isMatchingInboxFilter
    ) {
      commit(getTypeList(types.ADD_CONVERSATION), conversation);
      dispatch('contacts/setContact', sender);
    }
  },

  addMentions({ dispatch, rootState }, conversation) {
    if (isOnMentionsView(rootState)) {
      dispatch('updateConversation', conversation);
    }
  },

  addUnattended({ dispatch, rootState }, conversation) {
    if (isOnUnattendedView(rootState)) {
      dispatch('updateConversation', conversation);
    }
  },

  updateConversation({ commit, dispatch }, conversation) {
    const {
      meta: { sender },
    } = conversation;
    commit(getTypeList(types.UPDATE_CONVERSATION), conversation);

    dispatch('conversationLabels/setConversationLabel', {
      id: conversation.id,
      data: conversation.labels,
    });

    dispatch('contacts/setContact', sender);
  },

  updateConversationLastActivity(
    { commit },
    { conversationId, lastActivityAt, kanban_state }
  ) {
    commit(getTypeList(types.UPDATE_CONVERSATION_LAST_ACTIVITY), {
      lastActivityAt,
      conversationId,
      kanban_state
    });
  },

  setChatStatusFilter({ commit }, data) {
    commit(types.CHANGE_CHAT_STATUS_FILTER, data);
  },

  setChatSortFilter({ commit }, data) {
    commit(types.CHANGE_CHAT_SORT_FILTER, data);
  },

  updateAssignee({ commit }, data) {
    commit(types.UPDATE_ASSIGNEE, data);
  },

  updateConversationContact({ commit }, data) {
    if (data.id) {
      commit(`contacts/${types.SET_CONTACT_ITEM}`, data);
    }
    commit(types.UPDATE_CONVERSATION_CONTACT, data);
  },

  setActiveInbox({ commit }, inboxId) {
    commit(types.SET_ACTIVE_INBOX, inboxId);
  },

  muteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.mute(conversationId);
      commit(types.MUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },

  unmuteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.unmute(conversationId);
      commit(types.UNMUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },

  sendEmailTranscript: async (_, { conversationId, email }) => {
    try {
      await ConversationApi.sendEmailTranscript({ conversationId, email });
    } catch (error) {
      throw new Error(error);
    }
  },

  updateCustomAttributes: async (
    { commit },
    { conversationId, customAttributes }
  ) => {
    try {
      const response = await ConversationApi.updateCustomAttributes({
        conversationId,
        customAttributes,
      });
      const { custom_attributes } = response.data;
      commit(types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES, custom_attributes);
    } catch (error) {
      // Handle error
    }
  },

  setConversationFilters({ commit }, data) {
    commit(types.SET_CONVERSATION_FILTERS, data);
  },

  clearConversationFilters({ commit }) {
    commit(types.CLEAR_CONVERSATION_FILTERS);
  },

  setChatListFilters({ commit }, data) {
    commit(types.SET_CHAT_LIST_FILTERS, data);
  },

  updateChatListFilters({ commit }, data) {
    commit(types.UPDATE_CHAT_LIST_FILTERS, data);
  },

  assignPriority: async ({ dispatch }, { conversationId, priority }) => {
    try {
      await ConversationApi.togglePriority({
        conversationId,
        priority,
      });

      dispatch('setCurrentChatPriority', {
        priority,
        conversationId,
      });
    } catch (error) {
      // Handle error
    }
  },

  setCurrentChatPriority({ commit }, { priority, conversationId }) {
    commit(getTypeList(types.ASSIGN_PRIORITY), { priority, conversationId });
  },

  setContextMenuChatId({ commit }, chatId) {
    commit(types.SET_CONTEXT_MENU_CHAT_ID, chatId);
  },

  ...messageReadActions,
  ...messageTranslateActions,
};

export default actions;
