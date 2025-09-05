/* global axios */
import ApiClient from './ApiClient';

class CatalogsAPI extends ApiClient {
  constructor() {
    super('catalogs', { accountScoped: true });
  }

  // get(params = {}) {
  //   return axios.get(this.url, { params });
  // }

  bulkCreate(list) {
    return axios.post(`${this.url}/bulk_create`, { catalogs: list });
  }

  bulkDestroy(ids) {
    return axios.post(`${this.url}/bulk_destroy`, { ids });
  }
}

export default new CatalogsAPI();
