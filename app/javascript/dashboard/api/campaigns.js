import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }
  
  getQueryParams(params) {
    return axios.get(this.url, {
      params
    });
  }

  getContacts(id, status) {
    return axios.get(`${this.url}/${id}/messages`, {
      params: { status }
    });
  }
}

export default new CampaignsAPI();
