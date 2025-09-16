import ApiClient from './ApiClient';

class CalendarsApi extends ApiClient {
  constructor() {
    // => /api/v1/accounts/:account_id/calendars
    super('calendars', { accountScoped: true });
  }
}

export default new CalendarsApi();


