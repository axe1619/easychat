/* global axios */

import ApiClient from './ApiClient';

class Agents extends ApiClient {
  constructor() {
    super('agents', { accountScoped: true });
  }

  bulkInvite({ emails }) {
    return axios.post(`${this.url}/bulk_create`, {
      emails,
    });
  }

  limit_status() {
    return axios.get(`${this.url}/limit_status`);
  }
}

export default new Agents();
