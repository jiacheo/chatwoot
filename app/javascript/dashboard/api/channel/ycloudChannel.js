import ApiClient from '../ApiClient';

class YcloudChannel extends ApiClient {
  constructor() {
    super('channels/ycloud_channel', { accountScoped: true });
  }
}

export default new YcloudChannel();
