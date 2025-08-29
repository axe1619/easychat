<script>
import { mapGetters } from 'vuex';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import Thumbnail from '../Thumbnail.vue';
import MessagePreview from './MessagePreview.vue';
import router from '../../../routes';
import { frontendURL } from '../../../helper/URLHelper';
import InboxName from '../InboxName.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import CardLabels from './conversationCardComponents/CardLabels.vue';
import PriorityMark from './PriorityMark.vue';
import SLACardLabel from './components/SLACardLabel.vue';

export default {
  components: {
    CardLabels,
    InboxName,
    Thumbnail,
    TimeAgo,
    MessagePreview,
    PriorityMark,
    SLACardLabel,
  },
  mixins: [inboxMixin],
  props: {
    chat: {
      type: Object,
      default: () => {},
    },
    showAssignee: {
      type: Boolean,
      default: false,
    },
    selected: {
      type: Boolean,
      default: false,
    },
    hideInboxName: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      hovered: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChatId: 'getSelectChatId',
      inboxesList: 'inboxes/getInboxes',
      activeInbox: 'getSelectedInbox',
      accountId: 'getCurrentAccountId',
    }),
    chatMetadata() {
      return this.chat.meta || {};
    },

    assignee() {
      return this.chatMetadata.assignee || {};
    },

    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.chatMetadata.sender.id
      );
    },

    isActiveChat() {
      return this.currentChatId === this.chat.id;
    },

    unreadCount() {
      return this.chat.unread_count;
    },

    hasUnread() {
      return this.unreadCount > 0;
    },

    isInboxNameVisible() {
      return !this.activeInbox;
    },

    lastMessageInChat() {
      return getLastMessage(this.chat);
    },

    inbox() {
      const { inbox_id: inboxId } = this.chat;
      const stateInbox = this.$store.getters['inboxes/getInbox'](inboxId);
      return stateInbox;
    },

    showInboxName() {
      return (
        !this.hideInboxName &&
        this.isInboxNameVisible &&
        this.inboxesList.length > 1
      );
    },
    inboxName() {
      const stateInbox = this.inbox;
      return stateInbox.name || '';
    },
    hasSlaPolicyId() {
      return this.chat?.sla_policy_id;
    },
    getUrl() {
      return `accounts/${this.accountId}/board/conversations/${this.chat.id}`;
    },
  },
  methods: {
    onCardClick(e) {
      const { activeInbox, chat, isActiveChat } = this;
      if (isActiveChat) {
        return;
      }
      let params = {}
      if (chat.kanban_state.id) {
        params['columnId'] = chat.kanban_state.id
      }
      const path = frontendURL(this.getUrl, params);
      router.push({ path });
    },
    onCardHover() {
      this.hovered = true;
    },
    onCardLeave() {
      this.hovered = false;
    },
  },
};
</script>

<template>
  <div
    class="relative flex items-start flex-grow-0 flex-shrink-0 w-auto max-w-full px-4 py-0 border-t-0 border-b-0 border-l-2 border-r-0 border-transparent border-solid cursor-pointer conversation hover:bg-slate-25 dark:hover:bg-slate-800 group has-inbox-name"
    :class="{
      'active animate-card-select bg-slate-25 dark:bg-slate-800 border-woot-500':
        isActiveChat,
      'unread-chat': hasUnread,
      'has-inbox-name': showInboxName,
      'conversation-selected': selected,
    }" 
    @mouseenter="onCardHover" 
    @mouseleave="onCardLeave" 
    @click="onCardClick"
    >
    <Thumbnail 
      :src="currentContact.thumbnail" 
      :badge="inboxBadge" 
      :username="currentContact.name"
      :status="currentContact.availability_status" 
      size="40px" 
      />
    <div
      class="px-0 py-3 border-b group-hover:border-transparent flex-1 border-slate-50 dark:border-slate-800/75 w-[calc(100%-40px)]"
      >
      <div class="flex justify-between">
        <InboxName v-if="showInboxName" :show_inbox_name="true" :show_state="true" :inbox="inbox" :conversation="chat" />
        <div class="flex gap-2 ml-2 rtl:mr-2 rtl:ml-0 items-center">
          <span 
            v-if="showAssignee && assignee.name"
            class="text-slate-500 dark:text-slate-400 text-xs font-medium leading-3 py-0.5 px-0 inline-flex text-ellipsis overflow-hidden whitespace-nowrap"
            >
            <fluent-icon
              icon="person" 
              size="12" 
              class="text-slate-500 dark:text-slate-400" 
              />
            {{ assignee.name }}
          </span>
         <InboxName v-if="!showInboxName" :show_inbox_name="false" :show_state="true" :inbox="inbox" :conversation="chat" />
          <PriorityMark :priority="chat.priority" />
        </div>
      </div>
      <h4
        class="conversation--user text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis font-medium overflow-hidden whitespace-nowrap w-[calc(100%-70px)] text-slate-900 dark:text-slate-100"
        >
        {{ currentContact.name }}
      </h4>
      <MessagePreview 
        v-if="lastMessageInChat" 
        :message="lastMessageInChat"
        class="conversation--message my-0 mx-2 leading-6 h-6 max-w-[96%] w-[16.875rem] text-sm text-slate-700 dark:text-slate-200" 
        />
      <p 
      v-else
        class="conversation--message text-slate-700 dark:text-slate-200 text-sm my-0 mx-2 leading-6 h-6 max-w-[96%] w-[16.875rem] overflow-hidden text-ellipsis whitespace-nowrap"
        >
        <fluent-icon 
          size="16" 
          class="-mt-0.5 align-middle inline-block text-slate-600 dark:text-slate-300"
          icon="info" 
          />
        <span>
          {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
        </span>
      </p>
      <div class="absolute flex flex-col conversation--meta right-4 top-4">
        <span class="ml-auto font-normal leading-4 text-black-600 text-xxs">
          <TimeAgo 
            :last-activity-timestamp="chat.timestamp"
            :created-at-timestamp="chat.created_at"
            />
        </span>
        <span
          class="unread shadow-lg rounded-full hidden text-xxs font-semibold h-4 leading-4 ml-auto mt-1 min-w-[1rem] px-1 py-0 text-center text-white bg-green-400"
          >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </div>
      <CardLabels 
        :conversation-id="chat.id"
        :conversation-labels="chat.labels" 
        class="mt-0.5 mx-2 mb-0"
        >
        <template v-if="hasSlaPolicyId" #before>
          <SLACardLabel :chat="chat" class="ltr:mr-1 rtl:ml-1" />
        </template>
      </CardLabels>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.conversation {
  &.unread-chat {
    .unread {
      @apply block;
    }
    .conversation--message {
      @apply font-semibold;
    }
    .conversation--user {
      @apply font-semibold;
    }
  }

  &.compact {
    @apply pl-0;
    .conversation--details {
      @apply rounded-sm ml-0 pl-5 pr-2;
    }
  }

  &::v-deep .user-thumbnail-box {
    @apply mt-4;
  }

  &.conversation-selected {
    @apply bg-slate-25 dark:bg-slate-800;
  }

  &.has-inbox-name {
    &::v-deep .user-thumbnail-box {
      @apply mt-8;
    }
    .checkbox-wrapper {
      @apply mt-8;
    }
    .conversation--meta {
      @apply mt-4;
    }
  }

  .checkbox-wrapper {
    @apply h-10 w-10 flex items-center justify-center rounded-full cursor-pointer mt-4 hover:bg-woot-100 dark:hover:bg-woot-800;

    input[type='checkbox'] {
      @apply m-0 cursor-pointer;
    }
  }
}
</style>
