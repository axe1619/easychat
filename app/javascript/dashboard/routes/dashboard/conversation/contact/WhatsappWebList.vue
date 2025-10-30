<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, requiredIf } from '@vuelidate/validators';

export default {
  data() {
    return {
      showListMessage: false,
      selectMessage: false,
      list: [],
      message: "",
    };
  },
  setup() {
    return { v$: useVuelidate() };
  },
  validations() {
    return {
      message: {
        required: requiredIf(() => this.list.length == 0),
        minLength: minLength(5)
      },
      list: {
        required,
        minLength: minLength(1)
      }
    }
  },
  computed:{
    messageError(){
      if (this.v$.message.$error) {
        return this.$t('WHATSAPP_WEB.VALIDATION.MESSAGE.MIN_LENGTH')
      }
      if (this.v$.list.$error) {
        return this.$t('WHATSAPP_WEB.VALIDATION.LIST.MIN_LENGTH')
      }
      return '';
    }
  },
  methods: {
    save(){
      this.v$.$touch();
      if(this.v$.message.$error) return
      this.list.push(this.message)
      this.message = ""
      this.showListMessage = true
      this.v$.$reset()
    },
    toogleShowList() {
      this.v$.$reset()
      this.showListMessage = !this.showListMessage
    },
    remove(messageIndex) {
      this.list = this.list.filter((_, index) => index != messageIndex)
    },
    validate(){
      this.v$.$touch();
      return !this.v$.$invalid
    }
  },
};
</script>

<template>
  <div  class="flex flex-wrap mx-0">
    <div class="relative flex justify-end w-full">
      <div class="position-button flex gap-1">
        <woot-button
          v-if="!showListMessage"
          type="button"
          size="tiny"
          icon="save" 
          variant="smooth"
          color-scheme="secondary"
          @click="save"
        />
        <woot-button
          type="button"
          size="tiny"
          :icon="showListMessage ? 'add' : 'dismiss'"
          variant="smooth"
          color-scheme="secondary"
          @click="toogleShowList"
        />
      </div>
    </div>
    <div v-if="showListMessage" class="w-full">
      <div class="template__list-container">
        <div v-for="(message, index) in list">
          <button
            type="button"
            class="template__list-item"
          >
            <div class="flex items-center justify-end mb-2.5">
              <woot-button
                type="button"
                size="tiny"
                icon="dismiss" 
                variant="smooth"
                color-scheme="secondary"
                @click="remove(index)"
              />
            </div>
            <div>
                <p class="label-body">{{ message }}</p>
            </div>
          </button>
        </div>
      </div>
    </div>
    <textarea 
      v-else
      v-model="message" 
      rows="4" 
      class="template-input mt-2"
    >
    </textarea>
    <div>
      <span class="error-message">{{ messageError }}</span>
    </div>
  </div>
</template>

<style scoped lang="scss">
  .template__list-container {
    @apply bg-slate-25 dark:bg-slate-900 rounded-md max-h-[18.75rem] overflow-y-auto p-2.5;

    .template__list-item {
      @apply rounded-lg cursor-pointer block p-2.5 text-left w-full hover:bg-woot-50 dark:hover:bg-slate-800;

      .label-title {
        @apply text-sm;
      }

      .label-category {
        @apply mt-5;

        span {
          @apply text-sm font-semibold;
        }
      }

      .label-body {
        font-family: monospace;
      }
    }
  }
  .template-input {
   @apply bg-slate-25 dark:bg-slate-900 text-slate-700 dark:text-slate-100;
  }
  .position-button {
    position: absolute;
    top: -30px;
  }
  .error-message {
    @apply text-red-400 dark:text-red-400 block text-sm mb-2.5 w-full;
  }
</style>