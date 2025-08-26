import ApiClient from '../ApiClient';
import axios from 'axios';

class WhatsappInstancesClient extends ApiClient {
  constructor() {
    super('whatsapp_instances', { accountScoped: true });
  }

  // POST /whatsapp_instances/:instance_name/connect
  async connect(instanceName) {
  const slug = encodeURIComponent(instanceName);
  const res = await axios.post(`${this.url}/${slug}/connect`);
  return res.data;
}

  // GET /whatsapp_instances/:instance_name/state
  connectionState(instanceName) {
    const slug = encodeURIComponent(instanceName);
    return axios.get(`${this.url}/${slug}/state`);
  }

  // POST /whatsapp_instances/:instance_name/set_webhook
  setWebhook(instanceName, data) {
    const slug = encodeURIComponent(instanceName);
    return axios.post(`${this.url}/${slug}/set_webhook`, data);
  }
}

export default new WhatsappInstancesClient();
