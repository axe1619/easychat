/* global axios */
import ApiClient from './ApiClient';

class CatalogsAPI extends ApiClient {
  constructor() {
    super('catalogs', { accountScoped: true });
  }

  bulkCreate(list) {
    return axios.post(`${this.url}/bulk_create`, { catalogs: list });
  }

  bulkDestroy(ids) {
    return axios.post(`${this.url}/bulk_destroy`, { ids });
  }
}

export default new CatalogsAPI();
