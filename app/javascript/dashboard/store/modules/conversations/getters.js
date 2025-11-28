import { MESSAGE_TYPE } from 'shared/constants/messages';
import { applyPageFilters, sortComparator } from './helpers';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import boardConstants from 'dashboard/constants/board';

export const getSelectedChatConversation = ({
  allConversations,
  selectedChatId,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChatId);

export const getSelectedChatConversationBoard = ({
  boardConversations,
  selectedChatId,
  selectedChatColumnId
}) => {
  if (selectedChatColumnId == boardConstants.COLUMN_DEFAULT) {
    let column = boardConversations.find((col) => boardConstants.isColumnOrderZero(col))
    if (!column) return undefined
    return column.data.find((conversation) => conversation.id == selectedChatId)
  }
  let column = boardConversations.find((col) => col.id == selectedChatColumnId)
  if (!column) return undefined
  return column.data.find((conversation) => conversation.id == selectedChatId)
}

export const getSelectedRemoveChatConversationBoard = ({
  boardConversations,
  selectedChatId,
  selectedChatColumnId
}) => {
  let column
  if (selectedChatColumnId == boardConstants.COLUMN_DEFAULT) {
    column = boardConversations.find((col) => boardConstants.isColumnOrderZero(col))
  } else {
    column = boardConversations.find((col) => col.id == selectedChatColumnId)
  }
  if (!column) return undefined
  const conversationIndex = column.data.findIndex(c => c.id == selectedChatId)
  if (conversationIndex < 0) return undefined
  return column.data.splice(conversationIndex, 1)[0]
}

const getters = {
  getSuggestionMessages: ({ suggestionMessages }) => {
    return suggestionMessages
  },
  getSelectedSuggestionMessage: ({ selectedSuggestionMessage }) => {
    return selectedSuggestionMessage
  },
  getAllConversations: ({ allConversations, chatSortFilter: sortKey }) => {
    return allConversations.sort((a, b) => sortComparator(a, b, sortKey));
  },
  getBoardConversations: ({ boardConversations }) => {
    return boardConversations;
  },
  getSelectChatId: ({ selectedChatId, allConversations }) => {
    return selectedChatId
  },
  getSelectedChatBoard: (state) => {
    let selectedChat = getSelectedChatConversationBoard(state)
    return selectedChat || {};
  },
  getSelectedChat: ({ selectedChatId, allConversations }) => {
    const selectedChat = allConversations.find(
      conversation => conversation.id === selectedChatId
    );
    return selectedChat || {};
  },
  getSelectedChatAttachments: ({ selectedChatId, attachments }) => {
    return attachments[selectedChatId] || [];
  },
  getChatListFilters: ({ conversationFilters }) => conversationFilters,
  getLastEmailInSelectedChat: (stage, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    const { messages = [] } = selectedChat;
    const lastEmail = [...messages].reverse().find(message => {
      const {
        content_attributes: contentAttributes = {},
        message_type: messageType,
      } = message;
      const { email = {} } = contentAttributes;
      const isIncomingOrOutgoing =
        messageType === MESSAGE_TYPE.OUTGOING ||
        messageType === MESSAGE_TYPE.INCOMING;
      if (email.from && isIncomingOrOutgoing) {
        return true;
      }
      return false;
    });

    return lastEmail;
  },
  getMineChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserID = rootGetters.getCurrentUser?.id;

    return _state.allConversations.filter(conversation => {
      const { assignee } = conversation.meta;
      const isAssignedToMe = assignee && assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const isChatMine = isAssignedToMe && shouldFilter;

      return isChatMine;
    });
  },
  getAppliedConversationFilters: _state => {
    return _state.appliedFilters;
  },
  getAppliedConversationFiltersQuery: _state => {
    const hasAppliedFilters = _state.appliedFilters.length !== 0;
    return hasAppliedFilters ? filterQueryGenerator(_state.appliedFilters) : [];
  },
  getUnAssignedChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const isUnAssigned = !conversation.meta.assignee;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return isUnAssigned && shouldFilter;
    });
  },
  getUnReadChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const isUnRead = conversation.agent_last_seen_at == 0 || conversation.last_activity_incoming_at > conversation.agent_last_seen_at
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return isUnRead && shouldFilter;
    });
  },
  getAllStatusChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return shouldFilter;
    });
  },
  getChatListLoadingStatus: ({ listLoadingStatus }) => listLoadingStatus,
  getBoardListLoadingStatus: ({ boardListLoading }) => boardListLoading,
  getAllMessagesLoadedConversationBoard(_state) {
    const chat = getSelectedChatConversationBoard(_state);
    return !chat || chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getAllMessagesLoaded(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return !chat || chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = getSelectedChatConversation(_state);
    if (!chat) return [];
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        chatMessage.message_type === 0 &&
        chatMessage.private !== true
    ).length;
  },
  getChatStatusFilter: ({ chatStatusFilter }) => chatStatusFilter,
  getChatSortFilter: ({ chatSortFilter }) => chatSortFilter,
  getSelectedInbox: ({ currentInbox }) => currentInbox,
  getConversationById: _state => conversationId => {
    return _state.allConversations.find(
      value => value.id === Number(conversationId)
    );
  },
  getConversationParticipants: _state => {
    return _state.conversationParticipants;
  },
  getConversationLastSeen: _state => {
    return _state.conversationLastSeen;
  },

  getContextMenuChatId: _state => {
    return _state.contextMenuChatId;
  },
};

export default getters;
