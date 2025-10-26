<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';

export default {
  props: {
    onClose: {
      type: Function,
      default: () => { },
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      agentName: '',
      agentEmail: '',
      phoneNumber: '',
      activeDialCode: '',
      agentType: 'agent',
      vertical: 'bottom',
      horizontal: 'center',
      roles: [
        {
          name: 'administrator',
          label: this.$t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
        },
        {
          name: 'agent',
          label: this.$t('AGENT_MGMT.AGENT_TYPES.AGENT'),
        },
      ],
      show: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
    parsePhoneNumber() {
      return parsePhoneNumber(this.phoneNumber);
    },
    isPhoneNumberNotValid() {
      if (this.phoneNumber !== '') {
        return (
          !isPhoneNumberValid(this.phoneNumber, this.activeDialCode) ||
          (this.phoneNumber !== '' ? this.activeDialCode === '' : false)
        );
      }
      return false;
    },
    phoneNumberError() {
      if (this.activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (!isPhoneNumberValid(this.phoneNumber, this.activeDialCode)) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
      }
      return '';
    },
    setPhoneNumber() {
      if (this.parsePhoneNumber && this.parsePhoneNumber.countryCallingCode) {
        return this.phoneNumber;
      }
      if (this.phoneNumber === '' && this.activeDialCode !== '') {
        return '';
      }
      return this.activeDialCode
        ? `${this.activeDialCode}${this.phoneNumber}`
        : '';
    },
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(1),
    },
    agentEmail: {
      required,
      email,
    },
    agentType: {
      required,
    },
    phoneNumber: {
      required,
    },
    setPhoneNumber:{
      required
    }
  },

  methods: {
    onPhoneNumberInputChange(value, code) {
      this.activeDialCode = code;
    },
    setPhoneCode(code) {
      if (this.phoneNumber !== '' && this.parsePhoneNumber) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = this.phoneNumber.replace(
          `+${dialCode}`,
          `${code}`
        );
        this.phoneNumber = newPhoneNumber;
      } else {
        this.activeDialCode = code;
      }
    },
    async addAgent() {
      // console.log({
      //      name: this.agentName,
      //      email: this.agentEmail,
      //      role: this.agentType,
      //      phone_number: this.setPhoneNumber
      //    })
      try {
        await this.$store.dispatch('agents/create', {
          name: this.agentName,
          email: this.agentEmail,
          role: this.agentType,
          phone_number: this.phoneNumber
        });
        useAlert(this.$t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const {
          response: {
            data: {
              error: errorResponse = '',
              attributes: attributes = [],
              message: attrError = '',
            } = {},
          } = {},
        } = error;

        let errorMessage = '';
        if (error?.response?.status === 422 && !attributes.includes('base')) {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
        } else {
          errorMessage = this.$t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
        }
        useAlert(errorResponse || attrError || errorMessage);
      }
    },
  },
};
</script>

<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENT_MGMT.ADD.TITLE')" :header-content="$t('AGENT_MGMT.ADD.DESC')" />

      <form class="flex flex-col items-start w-full" @submit.prevent="addAgent()">
        <div class="w-full">
          <label :class="{ error: v$.agentName.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
            <input v-model.trim="agentName" type="text" :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
              @input="v$.agentName.$touch" />
          </label>
        </div>
        <div class="w-full">
          <!-- <label :class="{ error: v$.phoneNumber.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.LABEL') }}
            <input
              v-model.trim="phoneNumber"
              type="text"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.PLACEHOLDER')"
              @input="v$.phoneNumber.$touch"
            />
          </label> -->
          <label :class="{
            error: isPhoneNumberNotValid,
          }">
            {{ $t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.LABEL') }}
            <woot-phone-input v-model="phoneNumber" :value="phoneNumber" :error="isPhoneNumberNotValid"
              :placeholder="$t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.PLACEHOLDER')" @input="onPhoneNumberInputChange"
              @blur="v$.phoneNumber.$touch" @setCode="setPhoneCode" />
            <span v-if="isPhoneNumberNotValid" class="message">
              {{ phoneNumberError }}
            </span>
          </label>
        </div>
        <div class="w-full">
          <label :class="{ error: v$.agentType.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
            <select v-model="agentType">
              <option v-for="role in roles" :key="role.name" :value="role.name">
                {{ role.label }}
              </option>
            </select>
            <span v-if="v$.agentType.$error" class="message">
              {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>
        <div class="w-full">
          <label :class="{ error: v$.agentEmail.$error }">
            {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
            <input v-model.trim="agentEmail" type="text" :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')"
              @input="v$.agentEmail.$touch" />
          </label>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <div class="w-full">
            <woot-submit-button :disabled="v$.agentEmail.$invalid || (setPhoneNumber === '')||
              v$.agentName.$invalid ||
              uiFlags.isCreating
              " :button-text="$t('AGENT_MGMT.ADD.FORM.SUBMIT')" :loading="uiFlags.isCreating" />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>
