import ApiClient from './ApiClient';

class RagsApi extends ApiClient {
  constructor() {
    super('rags', { accountScoped: true });
  }
}

export default new RagsApi();
