<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.ycloudChannelId.$error }">
          {{ $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.YCLOUD_CHANNEL_ID.LABEL') }}
          <input
            v-model.trim="ycloudChannelId"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.YCLOUD_CHANNEL_ID.PLACEHOLDER')
            "
            @blur="$v.ycloudChannelId.$touch"
          />
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.ycloudChannelSecret.$error }">
          {{ $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.YCLOUD_CHANNEL_APIKEY.LABEL') }}
          <input
            v-model.trim="ycloudChannelApikey"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.YCLOUD_CHANNEL_APIKEY.PLACEHOLDER')
            "
            @blur="$v.ycloudChannelApikey.$touch"
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      channelName: '',
      ycloudChannelId: '',
      ycloudChannelApikey: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    ycloudChannelId: { required },
    ycloudChannelApikey: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const ycloudChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'ycloud',
              ycloud_channel_id: this.ycloudChannelId,
              ycloud_channel_apikey: this.ycloudChannelApikey,
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
        this.showAlert(
          this.$t('INBOX_MGMT.ADD.YCLOUD_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
