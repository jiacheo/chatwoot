<!-- Deprecated in favour of separate files for SMS and Whatsapp and also to implement new providers for each platform in the future-->
<template>
  <form class="row" @submit.prevent="createChannel()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.channelName.$error }">
        {{ $t('INBOX_MGMT.ADD.YCLOUD.CHANNEL_NAME.LABEL') }}
        <input
          v-model.trim="channelName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.YCLOUD.CHANNEL_NAME.PLACEHOLDER')"
          @blur="$v.channelName.$touch"
        />
        <span v-if="$v.channelName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.YCLOUD.CHANNEL_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.apikey.$error }">
        {{ $t('INBOX_MGMT.ADD.YCLOUD.YCLOUD_CHANNEL_APIKEY.LABEL') }}
        <input
          v-model.trim="apikey"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.YCLOUD.YCLOUD_CHANNEL_APIKEY.PLACEHOLDER')"
          @blur="$v.apikey.$touch"
        />
        <span v-if="$v.apikey.$error" class="message">{{
          $t('INBOX_MGMT.ADD.YCLOUD.YCLOUD_CHANNEL_APIKEY.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.YCLOUD.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

export default {
  mixins: [alertMixin],
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      apikey: '',
      medium: this.type,
      channelName: 'ycloud',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations() {
    if (this.phoneNumber) {
      return {
        channelName: { required },
        apikey: { required },
        medium: { required },
      };
    }
    return {
      channelName: { required },
      apikey: { required },
      medium: { required },
    };
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const ycloudChannel = await this.$store.dispatch(
          'inboxes/createYcloudChannel',
          {
            ycloud_channel: {
              name: this.channelName,
              medium: this.medium,
              apikey: this.apikey,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: ycloudChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.YCLOUD.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.messagingServiceHelptext {
  margin-top: -10px;
  margin-bottom: 15px;

  .checkbox {
    margin: 0px 4px;
  }
}
</style>
