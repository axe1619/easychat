<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import staticValidations, { getSorterTitleErrorMessage,getSorterDescriptionErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';
import { minLength, requiredIf } from '@vuelidate/validators';
import { getInboxSource } from 'dashboard/helper/inbox';
import SwitchButton from "dashboard/components/ui/Switch.vue";
import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';

export default {
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  components: {
    SwitchButton,
    InboxDropdownItem
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      description: '',
      color: '',
      enabledNotification: false,
      notify: [],
      options: [],
      selectedInbox: undefined
    };
  },
  validations() {
    return {
      ...staticValidations,
      notify: {
        required: requiredIf(() => this.enabledNotification),
        minLength: function () {
          if (!this.enabledNotification) return minLength(0)
          return minLength(1)
        }
      },
      selectedInbox: {
        required: requiredIf(() => this.enabledNotification),
      }
    }
  },
  computed: {
    ...mapGetters({
      uiFlags: 'sorter/getUIFlags',
      currentUser: 'getCurrentUser',
      notificationInboxes: 'inboxes/getNotificationInboxes',
    }),
    pageTitle() {
      return `${this.$t('SORTER.EDIT.TITLE')} - ${
        this.selectedResponse.name
      }`;
    },
    labelTitleErrorMessage() {
      const errorMessage = getSorterTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
    labelDescriptionErrorMessage() {
      const errorMessage = getSorterDescriptionErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
    disableButtonEdit() {
      return this.v$.name.$invalid || this.v$.description.$invalid || this.v$.notify.$invalid || this.v$.selectedInbox.$invalid || this.uiFlags.isCreating
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setFormValues() {
      this.name = this.selectedResponse.name;
      this.description = this.selectedResponse.description;
      this.color = this.selectedResponse.color;
      if (Object.keys(this.selectedResponse.notification).length > 0) {
        this.enabledNotification = true
        this.notify = this.selectedResponse.notification.phones.map((phone) => ({ name: phone }))
        this.options = this.selectedResponse.notification.phones.map((phone) => ({ name: phone }))
        this.selectedInbox = this.notificationInboxes.find((inbox) => inbox.id == this.selectedResponse.notification.inbox_id)
      }
    },
    editSorter() {
      let sorter = {
        id: this.selectedResponse.id,
        color: this.color,
        description: this.description,
        name: this.name.toLowerCase(),
        notification: {}
      }
      if (this.enabledNotification) {
        sorter.notification = {
          sender_id: this.currentUser.id,
          phones: this.notify.map((value) => value.name),
          inbox_id: this.selectedInbox.id
        }
      }
      this.$store.dispatch('sorter/update', sorter)
        .then(() => {
          useAlert(this.$t('SORTER.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          useAlert(this.$t('SORTER.EDIT.API.ERROR_MESSAGE'));
        });
    },
    computedInboxSource(inbox) {
      if (!inbox.channel_type) return '';
      const classByType = getInboxSource(
        inbox.channel_type,
        inbox.phone_number,
        inbox
      );
      return classByType;
    },
    onSwitchNotification() {
      this.enabledNotification = !this.enabledNotification
    },
    addNotify(value) {
      this.notify.push({ name: value })
      this.options.push({ name: value })
    }
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-wrap mx-0" @submit.prevent="editSorter">
      <woot-input
        v-model.trim="name"
        :class="{ error: v$.name.$error }"
        class="w-full label-name--input"
        :label="$t('SORTER.FORM.NAME.LABEL')"
        :placeholder="$t('SORTER.FORM.NAME.PLACEHOLDER')"
        :error="labelTitleErrorMessage"
        @input="v$.name.$touch"
      />

      <woot-text-area
        v-model.trim="description"
        :class="{ error: v$.description.$error }"
        class="w-full"
        :label="$t('SORTER.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('SORTER.FORM.DESCRIPTION.PLACEHOLDER')"
        data-testid="label-description"
        @input="v$.description.$touch"
        :error="labelDescriptionErrorMessage"
      />

      <div class="flex items-center justify-between w-full">
        <label>
          {{ $t('SORTER.FORM.COLOR.LABEL') }}
          <woot-color-picker v-model="color" />
        </label>
        <label class="flex flex-col gap-2 mb-4 items-end">
          <span>{{ $t('SORTER.NOTIFICATION.ENABLED') }}</span>
          <SwitchButton 
            :value="enabledNotification"
            @input="onSwitchNotification"
          />
        </label>
      </div>

      <div v-if="enabledNotification" class="w-full">
        <label>{{ $t('SORTER.NOTIFICATION.SEND') }}:</label>
        <multiselect
          v-model="selectedInbox"
          track-by="id"
          label="name"
          :placeholder="$t('FORMS.MULTISELECT.SELECT')"
          :max-height="140"
          close-on-select
          :options="notificationInboxes"
        >
          <template slot="singleLabel" slot-scope="{ option }">
            <InboxDropdownItem
              v-if="option.name"
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
            <span v-else>
              {{ $t('NEW_CONVERSATION.FORM.INBOX.PLACEHOLDER') }}
            </span>
          </template>
          <template slot="option" slot-scope="{ option }">
            <InboxDropdownItem
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
          </template>
        </multiselect>
        <label>{{ $t('SORTER.NOTIFICATION.NOTIFIED') }}:</label>
        <multiselect
          track-by="name"
          label="name"
          v-model="notify"
          :options="options"
          multiple
          taggable
          @tag="addNotify"
        />
      </div>
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <woot-button
          :is-disabled="disableButtonEdit"
          :is-loading="uiFlags.isUpdating"
        >
          {{ $t('SORTER.FORM.EDIT') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SORTER.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
// Label API supports only lowercase letters
.label-name--input {
  ::v-deep {
    input {
      @apply lowercase;
    }
  }
}
</style>
