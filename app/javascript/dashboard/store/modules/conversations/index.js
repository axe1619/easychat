import Vue from 'vue';
import types from '../../mutation-types';
import getters, {
  getSelectedChatConversation,
  getSelectedChatConversationBoard,
  getSelectedRemoveChatConversationBoard
} from './getters';
import actions from './actions';
import { findPendingMessageIndex } from './helpers';
import { MESSAGE_STATUS } from 'shared/constants/messages';
import wootConstants from 'dashboard/constants/globals';
import boardConstants from 'dashboard/constants/board';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { MESSAGE_TYPE } from '../../../../shared/constants/messages';

const state = {
  allConversations: [],
  boardConversations: [],
  boardListLoading: {},
  attachments: {},
  listLoadingStatus: true,
  chatStatusFilter: wootConstants.STATUS_TYPE.OPEN,
  chatSortFilter: wootConstants.SORT_BY_TYPE.LATEST,
  currentInbox: null,
  selectedChatId: null,
  selectedChatColumnId: null,
  appliedFilters: [],
  contextMenuChatId: null,
  conversationParticipants: [],
  conversationLastSeen: null,
  syncConversationsMessages: {},
  conversationFilters: {},
  suggestionMessages: [],
  selectedSuggestionMessage: '',
};

// mutations
export const mutations = {
  [types.SET_ALL_CONVERSATION](_state, conversationList) {
    const newAllConversations = [..._state.allConversations];
    conversationList.forEach(conversation => {
      const indexInCurrentList = newAllConversations.findIndex(
        c => c.id === conversation.id
      );
      if (indexInCurrentList < 0) {
        newAllConversations.push(conversation);
      } else if (conversation.id !== _state.selectedChatId) {
        // If the conversation is already in the list, replace it
        // Added this to fix the issue of the conversation not being updated
        // When reconnecting to the websocket. If the selectedChatId is not the same as
        // the conversation.id in the store, replace the existing conversation with the new one
        newAllConversations[indexInCurrentList] = conversation;
      } else {
        // If the conversation is already in the list and selectedChatId is the same,
        // replace all data except the messages array, attachments, dataFetched, allMessagesLoaded
        const existingConversation = newAllConversations[indexInCurrentList];
        newAllConversations[indexInCurrentList] = {
          ...conversation,
          allMessagesLoaded: existingConversation.allMessagesLoaded,
          messages: existingConversation.messages,
          dataFetched: existingConversation.dataFetched,
        };
      }
    });
    _state.allConversations = newAllConversations;
  },
  [types.EMPTY_ALL_CONVERSATION](_state) {
    _state.allConversations = [];
    _state.selectedChatId = null;
    _state.selectedChatColumnId = null;
  },
  [types.SET_CONVERSATION_BOARD](_state, list) {
    const { column, data: conversations } = list
    try {
      let columnFind = _state.boardConversations.find((col) => col.id == column.id)
      if (!columnFind) {
        _state.boardConversations = [..._state.boardConversations, { id: column.id, order: column.order, data: conversations }]
        return
      }
      conversations.forEach((conversation) => {
        let conversationIndex = columnFind.data.findIndex((c) => c.id == conversation.id)
        if (conversationIndex < 0) {
          columnFind.data.push(conversation)
        } else if (conversation.id !== _state.selectedChatId) {
          columnFind.data[conversationIndex] = conversation;
        } else {
          const existingConversation = columnFind.data[conversationIndex];
          columnFind.data[conversationIndex] = {
            ...conversation,
            allMessagesLoaded: existingConversation.allMessagesLoaded,
            messages: existingConversation.messages,
            dataFetched: existingConversation.dataFetched,
          };
        }
      })
      _state.boardConversations = _state.boardConversations.map((col) => {
        if (col.id == column.id) {
          return { ...columnFind, data: [...columnFind.data] }
        }
        return col
      })
    } catch (error) {
      console.warn({ error })
    }
  },
  [types.CLEAR_CONVERSATION_BOARD](_state) {
    _state.boardConversations = []
  },
  [types.SET_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'allMessagesLoaded', true);
  },
  [types.SET_SELECTED_SUGGESTION_MESSAGE](_state, message) {
    _state.selectedSuggestionMessage = message
  },
  [types.SET_SUGGESTION_MESSAGE](_state, messages) {
    _state.suggestionMessages = messages
  },
  [types.CLEAR_SUGGESTION_MESSAGE](_state) {
    _state.suggestionMessages = []
  },
  [types.SET_ALL_MESSAGES_BOARD_LOADED](_state) {
    try {
      const chat = getSelectedChatConversationBoard(_state);
      Vue.set(chat, 'allMessagesLoaded', true);
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.CLEAR_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    if (!chat) return
    Vue.set(chat, 'allMessagesLoaded', false);
  },

  [types.CLEAR_ALL_MESSAGES_LOADED_BOARD](_state) {
    const chat = getSelectedChatConversationBoard(_state);
    if (!chat) return
    Vue.set(chat, 'allMessagesLoaded', false);
  },

  [types.CLEAR_CURRENT_CHAT_WINDOW](_state) {
    _state.selectedChatId = null;
    _state.selectedChatColumnId = null;
  },

  [types.SET_PREVIOUS_CONVERSATIONS](_state, { id, data }) {
    if (data.length) {
      const [chat] = _state.allConversations.filter(c => c.id === id);
      chat.messages.unshift(...data);
    }
  },
  [types.SET_PREVIOUS_BOARD_CONVERSATIONS](_state, { id, data }) {
    if (data.length) {
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatId: id })
      chat.messages.unshift(...data);
    }
  },
  [types.SET_ALL_ATTACHMENTS](_state, { id, data }) {
    const attachments = _state.attachments[id] || [];

    attachments.push(...data);
    _state.attachments[id] = [...attachments];
  },
  [types.SET_MISSING_MESSAGES](_state, { id, data }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (!chat) return;
    Vue.set(chat, 'messages', data);
  },

  [types.SET_CURRENT_CHAT_WINDOW](_state, activeChat) {
    if (activeChat) {
      _state.selectedChatId = activeChat.id;
      _state.selectedChatColumnId = activeChat.kanban_state?.id || 0;
    }
  },

  [types.ASSIGN_AGENT](_state, assignee) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat.meta, 'assignee', assignee);
  },

  [types.ASSIGN_AGENT_BOARD](_state, assignee) {
    const chat = getSelectedChatConversationBoard(_state);
    Vue.set(chat.meta, 'assignee', assignee);
  },

  [types.ASSIGN_TEAM](_state, { team, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    Vue.set(chat.meta, 'team', team);
  },

  [types.ASSIGN_STATE_SORTER](_state, { state, conversationId }) {
    try {
      const [chat] = _state.allConversations.filter(c => c.id === conversationId);
      Vue.set(chat, 'conversations_state', state);
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.ASSIGN_STATE_REMARKETING](_state, { state, conversationId }) {
    try {
      const [chat] = _state.allConversations.filter(c => c.id === conversationId);
      Vue.set(chat, 'enabled_remarketing', state);
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.ASSIGN_TEAM_BOARD](_state, { team, conversationId }) {
    try {
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatId: conversationId })
      Vue.set(chat.meta, 'team', team);
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.UPDATE_CONVERSATION_LAST_ACTIVITY](
    _state,
    { lastActivityAt, conversationId }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat, 'last_activity_at', lastActivityAt);
    }
  },
  [types.UPDATE_CONVERSATION_BOARD_LAST_ACTIVITY](
    _state,
    { lastActivityAt, conversationId, kanban_state }
  ) {
    try {
      let selectedChatColumnId = kanban_state.id ?? _state.selectedChatColumnId ?? 0;
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatColumnId, selectedChatId: conversationId })
      if (chat) {
        Vue.set(chat, 'last_activity_at', lastActivityAt);
      }
    } catch (error) {
      console.warn({ error })
    }
  },
  [types.ASSIGN_PRIORITY](_state, { priority, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    Vue.set(chat, 'priority', priority);
  },
  [types.ASSIGN_PRIORITY_BOARD](_state, { priority, conversationId }) {
    try {
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatId: conversationId })
      Vue.set(chat, 'priority', priority);
    } catch (error) {
      console.warn({ error })
    }
  },
  [types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES](_state, custom_attributes) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'custom_attributes', custom_attributes);
  },

  [types.CHANGE_CONVERSATION_STATUS](
    _state,
    { conversationId, status, snoozedUntil }
  ) {
    const conversation =
      getters.getConversationById(_state)(conversationId) || {};
    Vue.set(conversation, 'snoozed_until', snoozedUntil);
    Vue.set(conversation, 'status', status);
  },

  [types.MUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'muted', true);
  },

  [types.UNMUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'muted', false);
  },

  [types.ADD_CONVERSATION_ATTACHMENTS](_state, message) {
    // early return if the message has not been sent, or has no attachments
    if (
      message.status !== MESSAGE_STATUS.SENT ||
      !message.attachments?.length
    ) {
      return;
    }

    const id = message.conversation_id;
    const existingAttachments = _state.attachments[id] || [];

    const attachmentsToAdd = message.attachments.filter(attachment => {
      // if the attachment is not already in the store, add it
      // this is to prevent duplicates
      return !existingAttachments.some(
        existingAttachment => existingAttachment.id === attachment.id
      );
    });

    // replace the attachments in the store
    _state.attachments[id] = [...existingAttachments, ...attachmentsToAdd];
  },

  [types.DELETE_CONVERSATION_ATTACHMENTS](_state, message) {
    if (message.status !== MESSAGE_STATUS.SENT) return;

    const { conversation_id: id } = message;
    const existingAttachments = _state.attachments[id] || [];
    if (!existingAttachments.length) return;

    _state.attachments[id] = existingAttachments.filter(attachment => {
      return attachment.message_id !== message.id;
    });
  },

  [types.ADD_MESSAGE]({ allConversations, selectedChatId }, message) {
    const { conversation_id: conversationId } = message;
    const [chat] = getSelectedChatConversation({
      allConversations,
      selectedChatId: conversationId,
    });
    if (!chat) return;

    const pendingMessageIndex = findPendingMessageIndex(chat, message);
    if (pendingMessageIndex !== -1) {
      Vue.set(chat.messages, pendingMessageIndex, message);
    } else {
      chat.conversations_state_name = message.conversations_state_name;
      chat.conversations_state = message.conversations_state;
      if (message.conversation) {
        chat.last_activity_incoming_at = message.conversation.last_activity_incoming_at
        chat.last_activity_outgoing_at = message.conversation.last_activity_outgoing_at
      }
      chat.messages.push(message);
      chat.timestamp = message.created_at;
      const { conversation: { unread_count: unreadCount = 0 } = {} } = message;
      chat.unread_count = unreadCount;
      if (selectedChatId === conversationId) {
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        if (message.message_type === MESSAGE_TYPE.INCOMING) {
          emitter.emit(BUS_EVENTS.MESSAGE_INCOMING);
        }
      }
    }
  },

  [types.ADD_MESSAGE_BOARD](_state, message) {
    try {
      const { conversation_id: conversationId, kanban_state } = message;
      let selectedChatColumnId = kanban_state?.id ?? _state.selectedChatColumnId ?? 0;
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatColumnId, selectedChatId: conversationId })
      if (!chat) return;

      const pendingMessageIndex = findPendingMessageIndex(chat, message);
      if (pendingMessageIndex !== -1) {
        Vue.set(chat.messages, pendingMessageIndex, message);
      } else {
        chat.conversations_state_name = message.conversations_state_name;
        chat.conversations_state = message.conversations_state;
        chat.messages.push(message);
        chat.timestamp = message.created_at;
        const { conversation: { unread_count: unreadCount = 0 } = {} } = message;
        chat.unread_count = unreadCount;
        if (_state.selectedChatId === conversationId) {
          emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
          emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        }
      }
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.ADD_CONVERSATION](_state, conversation) {
    _state.allConversations.push(conversation);
  },

  [types.ADD_CONVERSATION_BOARD](_state, conversation) {
    try {
      if (_state.boardConversations.length == 0) {
        return
      }
      _state.boardConversations = _state.boardConversations.map((column) => {
        if (boardConstants.isColumnOrderZero(column)) {
          return { ...column, data: [conversation, ...column.data] }
        }
        return column
      })
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.UPDATE_CONVERSATION](_state, conversation) {
    const { allConversations } = _state;
    const currentConversationIndex = allConversations.findIndex(
      c => c.id === conversation.id
    );
    if (currentConversationIndex > -1) {
      const { messages, ...conversationAttributes } = conversation;
      const currentConversation = {
        ...allConversations[currentConversationIndex],
        ...conversationAttributes,
      };
      Vue.set(allConversations, currentConversationIndex, currentConversation);
      if (_state.selectedChatId === conversation.id) {
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
      }
    } else {
      _state.allConversations.push(conversation);
    }
  },

  [types.UPDATE_CONVERSATION_BOARD](_state, conversation) {
    try {
      const { boardConversations } = _state;
      let columnId = conversation.kanban_state.id
      const matchFunction = (columnId == null)
        ? (column) => boardConstants.isColumnOrderZero(column)
        : (column) => column.id == columnId;
      const columnIndex = boardConversations.findIndex(matchFunction)
      if (columnIndex < 0) {
        return
      }
      const conversationIndex = boardConversations[columnIndex].data.findIndex(c => c.id === conversation.id)
      if (conversationIndex > -1) {
        const { messages, ...conversationAttributes } = conversation;
        const currentConversation = {
          ...boardConversations[columnIndex].data[conversationIndex],
          ...conversationAttributes,
        };
        Vue.set(boardConversations[columnIndex].data, conversationIndex, currentConversation);
        if (_state.selectedChatId === conversation.id) {
          emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
          emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        }
      } else {
        boardConversations[columnIndex].data.push(conversation)
      }
    } catch (error) {
      console.warn({ error })
    }
  },
  [types.SET_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = true;
  },

  [types.CLEAR_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = false;
  },

  [types.CLEAR_BOARD_LIST_LOADING_STATUS](_state, column_id) {
    _state.boardListLoading = { ..._state.boardListLoading, [column_id]: false }
  },

  [types.SET_BOARD_LIST_LOADING_STATUS](_state, column_id) {
    _state.boardListLoading = { ..._state.boardListLoading, [column_id]: true }
  },

  [types.UPDATE_MESSAGE_UNREAD_COUNT](
    _state,
    { id, lastSeen, unreadCount = 0 }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (chat) {
      Vue.set(chat, 'agent_last_seen_at', lastSeen);
      Vue.set(chat, 'unread_count', unreadCount);
    }
  },
  [types.CHANGE_CHAT_STATUS_FILTER](_state, data) {
    _state.chatStatusFilter = data;
  },

  [types.CHANGE_CHAT_SORT_FILTER](_state, data) {
    _state.chatSortFilter = data;
  },

  // Update assignee on action cable message
  [types.UPDATE_ASSIGNEE](_state, payload) {
    const [chat] = _state.allConversations.filter(c => c.id === payload.id);
    Vue.set(chat.meta, 'assignee', payload.assignee);
  },

  [types.UPDATE_CONVERSATION_CONTACT](_state, { conversationId, ...payload }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat.meta, 'sender', payload);
    }
  },

  [types.UPDATE_PROPERTIES_CONVERSATION](_state, { conversationId, properties }) {
    const [chat] = getSelectedChatConversation({
      allConversations: _state.allConversations,
      selectedChatId: conversationId
    })
    if (!chat) {
      return
    }
    Object.assign(chat, properties);
  },

  [types.UPDATE_PROPERTIES_CONVERSATION_BOARD](_state, { conversationId, columnId ,properties }) {
    const chat = getSelectedChatConversationBoard({
      boardConversations: _state.boardConversations,
      selectedChatId: conversationId,
      selectedChatColumnId: columnId ?? boardConstants.COLUMN_DEFAULT
    })
    if (!chat) {
      return
    }
    Object.assign(chat, properties);
  },

  [types.MOVE_CONVERSATION_BOARD](_state, { kanbanState }) {
    const chat = getSelectedRemoveChatConversationBoard(_state)
    if (!chat) {
      return
    }
    let column = _state.boardConversations.find((col) => col.id == kanbanState.id)
    if (column < 0) return
    _state.selectedChatColumnId = (kanbanState.order == 0) ? boardConstants.COLUMN_DEFAULT : kanbanState.id
    column.data.unshift(chat)
  },

  [types.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId ? parseInt(inboxId, 10) : null;
  },

  [types.SET_CONVERSATION_CAN_REPLY](_state, { conversationId, canReply }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat, 'can_reply', canReply);
    }
  },
  [types.SET_CONVERSATION_BOARD_CAN_REPLY](_state, { conversationId, canReply, kanban_state }) {
    try {
      let selectedChatColumnId = kanban_state.id ?? _state.selectedChatColumnId ?? 0;
      const chat = getSelectedChatConversationBoard({ ..._state, selectedChatColumnId, selectedChatId: conversationId })
      if (chat) {
        Vue.set(chat, 'can_reply', canReply);
      }
    } catch (error) {
      console.warn({ error })
    }
  },

  [types.CLEAR_CONTACT_CONVERSATIONS](_state, contactId) {
    const chats = _state.allConversations.filter(
      c => c.meta.sender.id !== contactId
    );
    Vue.set(_state, 'allConversations', chats);
  },

  [types.SET_CONVERSATION_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_CONVERSATION_FILTERS](_state) {
    _state.appliedFilters = [];
  },

  [types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION](
    _state,
    { conversationId, messageId }
  ) {
    _state.syncConversationsMessages[conversationId] = messageId;
  },

  [types.SET_CONTEXT_MENU_CHAT_ID](_state, chatId) {
    _state.contextMenuChatId = chatId;
  },

  [types.SET_CHAT_LIST_FILTERS](_state, data) {
    _state.conversationFilters = data;
  },
  [types.UPDATE_CHAT_LIST_FILTERS](_state, data) {
    _state.conversationFilters = { ..._state.conversationFilters, ...data };
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
