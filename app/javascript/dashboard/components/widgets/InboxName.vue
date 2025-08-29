<script>
import { getInboxClassByType } from 'dashboard/helper/inbox';

const CONVERSATION_STATUS = {
  open: { color: "#b1e3b3" },
  resolved: { color: "#ebcd81" },
  pending: { color: "#d2e9ff" },
  snoozed: { color: "#e99a9a" }
}

export default {
  props: {
    show_state:{
      type: Boolean,
      default:false
    },
    show_inbox_name: {
      type: Boolean,
      default: true
    },
    conversation: {
      type: Object,
      default: null 
    },
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      CONVERSATION_STATUS: CONVERSATION_STATUS
    }
  },
  computed: {
    computedInboxClass() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
    sorter(){
      return this.conversation?.conversations_state
    },
    status(){
      return this.conversation?.status
    }
  },
};
</script>

<template>
  <div
    class="inbox--name gap-1 inline-flex items-center py-0.5 px-0 leading-3 whitespace-nowrap font-medium bg-none text-slate-600 dark:text-slate-500 text-xs my-0 mx-2.5"
  >
    <template v-if="show_inbox_name">
      <fluent-icon
        class="mr-0.5 rtl:ml-0.5 rtl:mr-0"
        :icon="computedInboxClass"
        size="12"
      />
      {{ inbox.name }}
    </template>
    <template v-if="show_state && sorter && sorter.name">
      <small :style="{ backgroundColor: sorter.color }" class="inline-flex items-center rounded-md px-2 py-1 text-slate-900 dark:text-slate-100 font-medium">
        {{ sorter.name }}
      </small>
    </template>
    <template v-else-if="show_state">
      <small class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-slate-900 dark:text-slate-100 font-medium ring-1 ring-gray-500/10 ring-inset">
          no categorizada
      </small>
    </template>
    <small v-if="show_state" :style="{ backgroundColor: CONVERSATION_STATUS[status].color }" class="inline-flex items-center rounded-md px-2 py-1 text-slate-900 dark:text-slate-100 font-medium">
      {{ $t(`CONVERSATION.STATUS.${status.toUpperCase()}`) }}
    </small>
  </div>
</template>
