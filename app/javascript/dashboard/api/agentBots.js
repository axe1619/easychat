import ApiClient from './ApiClient';

class AgentBotsAPI extends ApiClient {
  constructor() {
    super('agent_bots', { accountScoped: true });
  }
  limit_status() {
    return axios.get(`${this.url}/limit_status`);
  }
}

export default new AgentBotsAPI();
