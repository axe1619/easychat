<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import Auth from '../../../../api/auth';
import wootConstants from 'dashboard/constants/globals';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';

const { AVAILABILITY_STATUS_KEYS } = wootConstants;

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    phoneNumber: {
      type: String,
      default: ''
    },
    email: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: '',
    },
    availability: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
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
      agentName: this.name,
      phoneNumberLocal: this.phoneNumber || '',
      activeDialCode: '',
      agentAvailability: this.availability,
      agentType: this.type,
      agentCredentials: {
        email: this.email,
      },
      show: true,
    };
  },
  validations: {
    agentName: {
      required,
      minLength: minLength(1),
    },
    agentType: {
      required,
    },
    agentAvailability: {
      required,
    },
    phoneNumberLocal: {
      required,
    },
    setPhoneNumber: {
      required
    }
  },
  computed: {
    pageTitle() {
      return `${this.$t('AGENT_MGMT.EDIT.TITLE')} - ${this.name}`;
    },
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
    availabilityStatuses() {
      return this.$t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST').map(
        (statusLabel, index) => ({
          label: statusLabel,
          value: AVAILABILITY_STATUS_KEYS[index],
          disabled:
            this.currentUserAvailability === AVAILABILITY_STATUS_KEYS[index],
        })
      );
    },
    parsePhoneNumber() {
      return parsePhoneNumber(this.phoneNumberLocal);
    },
    isPhoneNumberNotValid() {
      if (this.phoneNumberLocal !== '') {
        return (
          !isPhoneNumberValid(this.phoneNumberLocal, this.activeDialCode) ||
          (this.phoneNumberLocal !== '' ? this.activeDialCode === '' : false)
        );
      }
      return false;
    },
    phoneNumberError() {
      if (this.activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (!isPhoneNumberValid(this.phoneNumberLocal, this.activeDialCode)) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
      }
      return '';
    },
    setPhoneNumber() {
      if (this.parsePhoneNumber && this.parsePhoneNumber.countryCallingCode) {
        return this.phoneNumberLocal;
      }
      if (this.phoneNumberLocal === '' && this.activeDialCode !== '') {
        return '';
      }
      return this.activeDialCode
        ? `${this.activeDialCode}${this.phoneNumberLocal}`
        : '';
    },
  },
  mounted() {
    // this.$nextTick(() => {
    //   this.forceInputSync();
    // });

    this.$nextTick(() => {
      this.simulateUserEdit();
    });
    this.setDialCode()
  },

  methods: {
    forceInputSync() {
      console.log('<-- forceInputSync -->')
      if (!this.phoneNumberLocal) return;
      const original = this.phoneNumberLocal;
      const trimmed = original.slice(0, -1);
      this.phoneNumberLocal = trimmed;
      this.$nextTick(() => {
        this.phoneNumberLocal = original;
      });
    },
    simulateUserEdit() {
      const original = this.phoneNumberLocal;
      if (!original) return;

      // backspace virtual
      const trimmed = original.slice(0, -1);
      this.phoneNumberLocal = trimmed;

      // forzamos también el callback @input como si el hijo lo emitiera
      if (this.$refs.phoneInput) {
        // asumiendo que @input manda (value, code), tú puedes simularlo:
        this.onPhoneNumberInputChange(trimmed, this.activeDialCode);
      }

      // restaurar
      this.$nextTick(() => {
        this.phoneNumberLocal = original;
        if (this.$refs.phoneInput) {
          this.onPhoneNumberInputChange(original, this.activeDialCode);
        }
      });
    },
    safeParse(v) {
      try { return v ? parsePhoneNumber(v) : null; }
      catch { return null; }
    },
    setDialCode() {
      if (
        this.phoneNumberLocal !== '' &&
        this.parsePhoneNumber &&
        this.parsePhoneNumber.countryCallingCode
      ) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        this.activeDialCode = `+${dialCode}`;

      }
    },
    onPhoneNumberInputChange(value, code) {
      this.activeDialCode = code;
    },
    setPhoneCode(code) {
      if (this.phoneNumberLocal !== '' && this.parsePhoneNumber) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = this.phoneNumberLocal.replace(`+${dialCode}`, `${code}`);
        this.phoneNumberLocal = newPhoneNumber;
        // this.$nextTick(() => {
        //   this.$forceUpdate();
        // });
      } else {
        this.activeDialCode = code;
      }
    },
    async editAgent() {
      if(this.phoneNumberLocal !== ''){
        this.phoneNumberLocal = this.phoneNumberLocal.replace(this.activeDialCode, '')
      }
      try {
        console.log({
          id: this.id,
          name: this.agentName,
          phone_number: this.activeDialCode + this.phoneNumberLocal,
          activeDialCode: this.activeDialCode,
          role: this.agentType,
          availability: this.agentAvailability,
        })

        await this.$store.dispatch('agents/update', {
          id: this.id,
          name: this.agentName,
          phone_number: this.activeDialCode + this.phoneNumberLocal,
          role: this.agentType,
          availability: this.agentAvailability,
        });
        useAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        useAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async resetPassword() {
      try {
        await Auth.resetPassword(this.agentCredentials);
        useAlert(
          this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_SUCCESS_MESSAGE')
        );
      } catch (error) {
        useAlert(this.$t('AGENT_MGMT.EDIT.PASSWORD_RESET.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="w-full" @submit.prevent="editAgent()">
        <div class="w-full">
          <label :class="{ error: v$.agentName.$error }">
            {{ $t('AGENT_MGMT.EDIT.FORM.NAME.LABEL') }}
            <input v-model.trim="agentName" type="text" :placeholder="$t('AGENT_MGMT.EDIT.FORM.NAME.PLACEHOLDER')"
              @input="v$.agentName.$touch" />
          </label>
        </div>

        <div class="w-full">
          <label :class="{
            error: isPhoneNumberNotValid,
          }">
            {{ $t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.LABEL') }}
            <!-- :error="isPhoneNumberNotValid" -->
            <woot-phone-input ref="phoneInput" v-model="phoneNumberLocal" 
              :placeholder="$t('AGENT_MGMT.ADD.FORM.PHONE_NUMBER.PLACEHOLDER')" @input="onPhoneNumberInputChange"
              @blur="v$.phoneNumberLocal.$touch" @setCode="setPhoneCode" />
            <!-- <span v-if="isPhoneNumberNotValid" class="message">
              {{ phoneNumberError }}
            </span> -->
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.agentType.$error }">
            {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.LABEL') }}
            <select v-model="agentType">
              <option v-for="role in roles" :key="role.name" :value="role.name">
                {{ role.label }}
              </option>
            </select>
            <span v-if="v$.agentType.$error" class="message">
              {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_TYPE.ERROR') }}
            </span>
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.agentAvailability.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.AVAILABILITY.LABEL') }}
            <select v-model="agentAvailability">
              <option v-for="role in availabilityStatuses" :key="role.value" :value="role.value">
                {{ role.label }}
              </option>
            </select>
            <span v-if="v$.agentAvailability.$error" class="message">
              {{ $t('AGENT_MGMT.EDIT.FORM.AGENT_AVAILABILITY.ERROR') }}
            </span>
          </label>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <div class="w-[50%]">
            <WootSubmitButton :disabled="v$.agentType.$invalid ||
              v$.agentName.$invalid ||
              uiFlags.isUpdating
              " :button-text="$t('AGENT_MGMT.EDIT.FORM.SUBMIT')" :loading="uiFlags.isUpdating" />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('AGENT_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
          <div class="w-[50%] text-right">
            <woot-button icon="lock-closed" variant="clear" @click.prevent="resetPassword">
              {{ $t('AGENT_MGMT.EDIT.PASSWORD_RESET.ADMIN_RESET_BUTTON') }}
            </woot-button>
          </div>
        </div>
      </form>
    </div>
  </Modal>
</template>
