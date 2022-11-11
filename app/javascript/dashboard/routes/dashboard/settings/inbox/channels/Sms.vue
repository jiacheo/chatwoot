<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <div class="medium-8 columns">
      <label>
        {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.TWILIO') }}
          </option>
          <option value="ycloud">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.YCLOUD') }}
          </option>
          <option value="bandwidth">
            {{ $t('INBOX_MGMT.ADD.SMS.PROVIDERS.BANDWIDTH') }}
          </option>
        </select>
      </label>
    </div>
    <twilio v-if="provider === 'twilio'" type="sms" />
    <ycloud v-else-if="provider === 'ycloud'" type="sms" />
    <bandwidth-sms v-else />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader';
import BandwidthSms from './BandwidthSms.vue';
import Twilio from './Twilio';
import YCloud from './YCloud';

export default {
  components: {
    PageHeader,
    Twilio,
    BandwidthSms,
    YCloud,
  },
  data() {
    return {
      provider: 'ycloud',
    };
  },
};
</script>
